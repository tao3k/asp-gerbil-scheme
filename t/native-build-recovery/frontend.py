#!/usr/bin/env python3
"""Controlled frontend failure with live backend jobs and a late frontend producer."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--make-source', type=Path, required=True)
p.add_argument('--patch', type=Path, required=True)
p.add_argument('--native-gsc', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--qualify', action='store_true')
p.add_argument('--fail-backend', action='store_true')
p.add_argument('--coordinator-fault', action='store_true')
p.add_argument('--experimental-lease', action='store_true')
p.add_argument('--timeout', type=float, default=30)
a = p.parse_args()
assert a.native_gsc.is_file() and os.access(a.native_gsc, os.X_OK)
assert not a.fail_backend or a.qualify
assert not a.coordinator_fault or a.qualify
assert not a.experimental_lease or a.qualify
fault_cause = 'Controlled coordinator failure' if a.coordinator_fault else 'Controlled frontend failure'
base = a.make_source.read_bytes()
bases = json.loads((a.patch.parent / 'patch-bases.json').read_text())
assert hashlib.sha256(base).hexdigest() == bases[a.patch.name.split('-')[0]]['sourceSha256']
a.output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='gerbil-frontend-drain-') as temporary:
    root = Path(temporary).resolve()
    (root / 'gerbil.pkg').write_text('(package: frontend-drain)\n')
    lib = root / 'lib'
    (lib / 'frontend-drain').mkdir(parents=True)
    controls = root / 'controls'; controls.mkdir()
    for name, value in [('good', 42), ('bad', 44), ('late', 43)]:
        (root / (name + '.ss')).write_text(f'(export value)\n(def value {value})\n')
    (root / 'dependent.ss').write_text('(import ./bad)\n(export answer)\n(def answer value)\n')
    source = root / 'native-make.ss'; source.write_bytes(base)
    subprocess.run(['patch', '-f', str(source)], input=a.patch.read_text(), text=True, capture_output=True, check=True)
    patched_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    # Fault injection sits in the frontend build action. The production patch
    # does not select targets by source name or contain these control markers.
    text = source.read_text()
    needle = '(def (build spec settings)\n'
    assert text.count(needle) == 1
    literal = lambda name: json.dumps(str(controls / name))
    text = text.replace(needle, '''(def controlled-frontend-enabled (make-parameter #t))
(export controlled-frontend-enabled)
(def (control-write path)
  (call-with-output-file path (lambda (p) (display "ready" p))))
(def (control-wait path)
  (let loop () (unless (file-exists? path) (thread-sleep! .01) (loop))))
''' + needle + '''  (when (controlled-frontend-enabled)
    (cond
      ((equal? spec "late")
       (control-write ''' + literal('late-active') + ''')
       (control-wait ''' + literal('late-release') + '''))
      ((equal? spec "bad")
       (control-wait ''' + literal('backend-started') + ''')
       (control-wait ''' + literal('late-active') + ''')
       (control-write ''' + literal('frontend-fault') + ''')
       (error "Controlled frontend failure"))))
''')
    if a.coordinator_fault:
        coordinator_point = '(mod (import/mx file)))\n'
        assert text.count(coordinator_point) == 1
        text = text.replace(coordinator_point, coordinator_point +
            '        (when (and (controlled-frontend-enabled) (equal? spec "bad"))\n' +
            '          (control-wait ' + literal('backend-started') + ')\n' +
            '          (control-wait ' + literal('late-active') + ')\n' +
            '          (control-write ' + literal('frontend-fault') + ')\n' +
            '          (error "Controlled coordinator failure"))\n')
    if a.experimental_lease:
        assert text.count('(def (make buildspec . rest)') == 1
        text = text.replace('(def (make buildspec . rest)', '(def (make/without-experimental-lease buildspec . rest)')
        text += '\n(def (make buildspec . rest)\n  (def settings (apply make-settings rest))\n  (def directory (settings-libdir settings))\n  (create-directory* directory)\n  (def lease (path-expand ".experimental-native-write-lease" directory))\n  (create-directory lease)\n  ;; This experiment relies on the repaired ordinary-failure drain. Forced\n  ;; death still leaves the directory claim; no automatic reclamation is added.\n  (def result\n    (with-catch\n      (lambda (failure) (delete-directory lease) (raise failure))\n      (lambda () (apply make/without-experimental-lease buildspec rest))))\n  (delete-directory lease)\n  result)\n'
    source.write_text(text)
    backend = controls / 'gsc'  
    backend.write_text('#!' + sys.executable + '\n' + '''from pathlib import Path
import json, os, sys, time
control = Path(__file__).parent
name = Path(sys.argv[-1]).name
record = control / (name + '.ready')
temporary = record.with_suffix('.pending')
temporary.write_text(json.dumps({'pid': os.getpid(), 'pgid': os.getpgrp(), 'input': sys.argv[-1]}))
temporary.replace(record)
(control / 'backend-started').touch()
while not (control / 'backend-release').exists(): time.sleep(.01)
arguments = sys.argv[1:]
if (control / 'backend-fail').exists():
    arguments = [*arguments[:-1], '-cc-options', '-fasp-native-failure', arguments[-1]]
os.execv(''' + repr(str(a.native_gsc.resolve())) + ', [' + repr(str(a.native_gsc.resolve())) + ''', *arguments])
'''); backend.chmod(0o700)
    if a.fail_backend: (controls / 'backend-fail').touch()
    env = dict(os.environ, GERBIL_PATH=str(root), GERBIL_LOADPATH=str(lib), GERBIL_GSC=str(backend), GERBIL_BUILD_CORES='12')
    for key in ('SDKROOT', 'DEVELOPER_DIR'): env.pop(key, None)
    call = '(make ["good" "bad" "late" "dependent"] srcdir: ' + json.dumps(str(root)) + ' libdir: ' + json.dumps(str(lib)) + ' parallelize: 12)'
    expr = '(import ' + json.dumps(str(source)) + ') (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () '
    expr += '(def observed #f) (with-catch (lambda (e) (set! observed e) (display-exception e (current-error-port)) (force-output (current-error-port))) (lambda () ' + call + ')) '
    expr += '(unless observed (error "Expected frontend failure")) (displayln "FAILURE-RETURNED") (control-write ' + literal('failure-returned') + ') '
    # control helpers are deliberately exported only from the instrumented copy.
    text = source.read_text().replace('(export controlled-frontend-enabled)', '(export controlled-frontend-enabled control-write control-wait)')
    source.write_text(text)
    if a.qualify:
        expr += '(control-wait ' + literal('recovery-release') + ') (controlled-frontend-enabled #f) (displayln "RECOVERY-START") ' + call + ' (displayln "RECOVERY-OK") (control-write ' + literal('recovery-done') + ') '
        expr += '(control-wait ' + literal('warm-release') + ') (displayln "WARM-START") ' + call + ' (displayln "WARM-OK") '
    else:
        expr += '(control-wait ' + literal('finish-test') + ') '
    expr += '(displayln "FRONTEND-PROBE-OK")))'
    out = a.output / 'build.out'; err = a.output / 'build.err'
    processes = []
    observations = []
    def mark(name, **fields):
        row = dict(name=name, **fields); observations.append(row)
        (a.output / 'receipts.json').write_text(json.dumps(observations, indent=2)+'\n')
        print('PROBE-END', json.dumps(row), flush=True)
    def wait(path):
        deadline = time.monotonic()+a.timeout
        while not path.exists():
            assert process.poll() is None, err.read_text()
            if time.monotonic()>deadline: raise TimeoutError(str(path))
            time.sleep(.01)
    def no_return(name):
        # A bounded observation while both controlled gates remain held.
        deadline = time.monotonic()+.25
        while time.monotonic()<deadline:
            assert process.poll() is None, err.read_text()
            assert not (controls / 'failure-returned').exists(), 'failure returned with active producers'
            if a.experimental_lease:
                assert (lib / '.experimental-native-write-lease').is_dir()
            time.sleep(.01)
        mark(name, returned=False)
    try:
        print('PROBE-START frontend-failure', flush=True)
        with out.open('w') as stdout, err.open('w') as stderr:
            process = subprocess.Popen(['gxi', '-e', expr], env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        processes.append(process)
        wait(controls / 'frontend-fault')
        if a.qualify:
            no_return('waits-for-late-frontend')
        else:
            wait(controls / 'failure-returned')
            mark('early-return', returnedBeforeBackendRelease=True, lateFrontendHeld=True)
        (controls / 'late-release').touch()
        wait(controls / 'late.scm.ready')
        wait(controls / 'late~0.scm.ready')
        records = [json.loads(path.read_text()) for path in controls.glob('*.ready')]
        assert all(record['pgid']==process.pid for record in records)
        if a.qualify:
            no_return('waits-for-native-backends')
        else:
            mark('late-submission-after-return', capturedLateBackendJobs=2)
        (controls / 'backend-release').touch()
        wait(controls / 'failure-returned')
        assert fault_cause in err.read_text()
        assert not list(lib.rglob('*.native-complete'))
        if a.qualify:
            # Each acknowledged direct backend must be gone before make returns.
            for record in records:
                try: os.kill(record['pid'],0)
                except ProcessLookupError: pass
                else: raise AssertionError('backend survived failure return')
            if a.fail_backend: assert 'Compilation error' in err.read_text()
            if a.experimental_lease:
                assert not (lib / '.experimental-native-write-lease').exists()
            mark('drained-failure', experimentalLeaseReleased=a.experimental_lease, firstError=fault_cause, failureLocation='coordinator' if a.coordinator_fault else 'worker', secondaryBackendFailure=a.fail_backend,
                 nativeJobsExited=len(records), receiptCount=0)
            (controls / 'backend-fail').unlink(missing_ok=True)
            (controls / 'recovery-release').touch(); wait(controls / 'recovery-done')
            assert len(list(lib.rglob('*.native-complete')))==4
            before={str(path): (path.stat().st_mtime_ns, path.stat().st_size) for path in lib.rglob('*') if path.is_file()}
            (controls / 'warm-release').touch()
        else:
            (controls / 'finish-test').touch()
        status=process.wait(timeout=a.timeout)
        assert status==0 and 'FRONTEND-PROBE-OK' in out.read_text(), err.read_text()
        if a.qualify:
            after={str(path): (path.stat().st_mtime_ns, path.stat().st_size) for path in lib.rglob('*') if path.is_file()}
            assert before==after
            output=out.read_text(); recovery=output.split('RECOVERY-START')[1].split('RECOVERY-OK')[0]
            assert all(recovery.count('... compile '+name+'\n')==1 for name in ['good','bad','late','dependent'])
            assert '... compile ' not in output.split('WARM-START')[1]
            mark('same-process-recovery-and-warm', receiptCount=4, recoveryCompileCount=4, warmCompileCount=0, warmNoWrite=True)
            for name, value, binding in [('good',42,'value'),('late',43,'value'),('dependent',44,'answer')]:
                runtime='(import :frontend-drain/'+name+') (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () (unless (= '+binding+' '+str(value)+') (error "Wrong runtime")) (displayln "RUNTIME-OK")))'
                result=subprocess.run(['gxi','-e',runtime],env=env,capture_output=True,text=True,timeout=a.timeout)
                (a.output/(name+'.out')).write_text(result.stdout); (a.output/(name+'.err')).write_text(result.stderr)
                assert result.returncode==0 and 'RUNTIME-OK' in result.stdout,result.stderr
                mark('runtime-'+name, answer=value, exit=result.returncode)
        (a.output/'identity.json').write_text(json.dumps(dict(patchedSourceSha256=patched_hash,
            instrumentedSourceSha256=hashlib.sha256(source.read_bytes()).hexdigest(), patchSha256=hashlib.sha256(a.patch.read_bytes()).hexdigest(),
            firstCause=fault_cause, processExit=status),indent=2)+'\n')
    finally:
        for process in processes:
            try: os.killpg(process.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            process.wait()
print('FRONTEND-DRAIN-QUALIFIED' if a.qualify else 'FRONTEND-EARLY-RETURN-REPRODUCED',flush=True)
