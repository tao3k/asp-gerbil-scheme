#!/usr/bin/env python3
"""Reproduce shared-output writer corruption and study a fail-closed directory lease.

The lease is an isolated experiment, not part of the retained compiler patches.
"""
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

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--make-source', type=Path, required=True)
parser.add_argument('--patch', type=Path, required=True)
parser.add_argument('--native-gsc', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--timeout', type=float, default=30)
args = parser.parse_args()
assert args.native_gsc.is_file() and os.access(args.native_gsc, os.X_OK)
args.output.mkdir(parents=True, exist_ok=True)
sha = lambda data: hashlib.sha256(data).hexdigest()
base = args.make_source.read_bytes()
bases = json.loads((args.patch.parent / 'patch-bases.json').read_text())
assert sha(base) == bases[args.patch.name.split('-')[0]]['sourceSha256']
rows = []

# Fail closed on errors: no automatic stale-owner reclamation is attempted.
# Canonical, identical output roots are supplied by this harness. Aliased or
# overlapping roots and noncooperating writers are outside this experiment.
LEASE = '''(def (with-experimental-output-lease settings body)
  (def directory (settings-libdir settings))
  (create-directory* directory)
  (def lease (path-expand ".experimental-native-write-lease" directory))
  (with-catch
    (lambda (failure)
      (if (file-exists? lease)
        (error "Native output namespace is busy or abandoned" lease)
        (raise failure)))
    (lambda () (create-directory lease)))
  ;; Release only on success. Failure or death leaves a claim until an operator
  ;; has proved that the old writer's entire backend process group is dead.
  (def result (body))
  (delete-directory lease)
  result)

(def (make buildspec . rest)
  (with-experimental-output-lease (apply make-settings rest)
    (lambda () (apply make/without-experimental-lease buildspec rest))))

(def (make-clean buildspec . rest)
  (with-experimental-output-lease (apply make-settings rest)
    (lambda () (apply make-clean/without-experimental-lease buildspec rest))))

'''

def lease_source(source):
    assert source.count('(def (make buildspec . rest)') == 1
    assert source.count('(def (make-clean . args)') == 1
    return (source.replace('(def (make buildspec . rest)', '(def (make/without-experimental-lease buildspec . rest)')
            .replace('(def (make-clean . args)', '(def (make-clean/without-experimental-lease . args)')
            + '\n' + LEASE)

with tempfile.TemporaryDirectory(prefix='gerbil-writer-study-') as temporary:
    root = Path(temporary).resolve()
    patched = root / 'native-make.ss'
    patched.write_bytes(base)
    subprocess.run(['patch', '-f', str(patched)], input=args.patch.read_text(),
                   text=True, capture_output=True, check=True)
    current_source = patched.read_text()
    experimental = root / 'lease-make.ss'
    experimental.write_text(lease_source(current_source))
    identities = dict(baseSha256=sha(base), patchSha256=sha(args.patch.read_bytes()),
                      patchedSourceSha256=sha(patched.read_bytes()),
                      experimentalSourceSha256=sha(experimental.read_bytes()),
                      nativeGscSha256=sha(args.native_gsc.read_bytes()))

    class Case:
        def __init__(self, name, lease=False):
            self.name = name
            self.directory = root / name
            self.lib = self.directory / 'lib'
            self.outputs = self.lib / 'writers'
            self.outputs.mkdir(parents=True)
            self.log = args.output / name
            self.log.mkdir(exist_ok=True)
            self.source = experimental if lease else patched
            self.processes = []
            for writer, value in [('a', 42), ('b', 43)]:
                src = self.directory / writer
                src.mkdir()
                (src / 'gerbil.pkg').write_text('(package: writers)\n')
                (src / 'middle.ss').write_text(f'(export answer)\n(def answer {value})\n')
                control = self.directory / (writer + '-control')
                control.mkdir()
                backend = control / 'gsc'
                # Capture each job's actual generated Scheme input before any
                # competing frontend rewrites it. Real gsc still writes the
                # shared object path. -o preserves the original output name.
                # This controlled schedule proves a missing exclusion boundary;
                # it does not measure naturally occurring race frequency.
                backend.write_text('#!' + sys.executable + '\n' + '''import sys, os, time, json, shutil
from pathlib import Path
control = Path(__file__).parent
arguments = sys.argv[1:]
source = Path(arguments[-1])
assert source.suffix == '.scm' and '-o' not in arguments
frozen = control / source.name
shutil.copyfile(source, frozen)
target = source.with_suffix('.o1')
(control / (source.name + '.ready')).write_text(json.dumps({'pid': os.getpid(), 'pgid': os.getpgrp(), 'arguments': arguments, 'source': str(source), 'target': str(target)}))
while not (control / 'release').exists():
    if (control / 'probe-after-owner-death').exists():
        (control / (source.name + '.alive')).write_text(str(os.getpid()))
    time.sleep(.01)
os.execv(''' + repr(str(args.native_gsc.resolve())) + ', [' + repr(str(args.native_gsc.resolve())) + ''', *arguments[:-1], '-o', str(target), str(frozen)])
''')
                backend.chmod(0o700)

        def environment(self, writer):
            env = dict(os.environ, GERBIL_PATH=str(self.directory / writer),
                       GERBIL_LOADPATH=str(self.lib), GERBIL_BUILD_CORES='12',
                       GERBIL_GSC=str(self.directory / (writer + '-control') / 'gsc'))
            for key in ('SDKROOT', 'DEVELOPER_DIR'):
                env.pop(key, None)
            return env

        def start(self, name, writer, *, force=True, clean=False, runtime=None):
            print('PROBE-START', self.name, name, flush=True)
            if runtime is None:
                body = ('(make-clean' if clean else '(make') + ' ["middle"] srcdir: ' + json.dumps(str(self.directory / writer)) + ' libdir: ' + json.dumps(str(self.lib))
                if not clean:
                    body += ' parallelize: 12 force: ' + ('#t' if force else '#f')
                body += ') (displayln "BUILD-OK")'
                imports = '(import ' + json.dumps(str(self.source)) + ')'
            else:
                imports = '(import :writers/middle)'
                body = '(unless (= answer ' + str(runtime) + ') (error "wrong runtime value" answer)) (displayln "RUNTIME-OK " answer)'
            expression = imports + ' (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () ' + body + '))'
            out = self.log / (name + '.out')
            err = self.log / (name + '.err')
            with out.open('w') as stdout, err.open('w') as stderr:
                process = subprocess.Popen(['gxi', '-e', expression], env=self.environment(writer),
                                           stdout=stdout, stderr=stderr, start_new_session=True)
            entry = dict(process=process, name=name, writer=writer, started=time.monotonic(), out=out, err=err,
                         runtime=runtime, clean=clean)
            self.processes.append(entry)
            return entry

        def captured(self, entry):
            control = self.directory / (entry['writer'] + '-control')
            witness = self.outputs / 'middle.native-interface'
            while True:
                ready = list(control.glob('*.ready'))
                if len(ready) == 2 and witness.exists() and witness.read_bytes() == (self.outputs / 'middle.ssi').read_bytes():
                    captures = []
                    for record in sorted(ready):
                        data = json.loads(record.read_text())
                        assert data['pgid'] == entry['process'].pid, 'backend escaped owned process group'
                        data['inputSha256'] = sha((control / record.name.removesuffix('.ready')).read_bytes())
                        captures.append(data)
                    (self.log / (entry['name'] + '.captures.json')).write_text(json.dumps(captures, indent=2) + '\n')
                    print('BACKENDS-CAPTURED', self.name, entry['writer'], flush=True)
                    return
                assert entry['process'].poll() is None, entry['err'].read_text()
                if time.monotonic() - entry['started'] > args.timeout:
                    raise TimeoutError('backend capture timeout')
                time.sleep(.01)

        def release(self, writer):
            (self.directory / (writer + '-control') / 'release').touch()

        def inventory(self):
            return {p.name: sha(p.read_bytes()) for p in self.outputs.iterdir() if p.is_file()}

        def finish(self, entry, status=0, cause=None, compile_count=None):
            observed = entry['process'].wait(timeout=args.timeout)
            stdout, stderr = entry['out'].read_text(), entry['err'].read_text()
            receipt = self.outputs / 'middle.native-complete'
            row = dict(case=self.name, name=entry['name'], writer=entry['writer'], exit=observed,
                       wallSeconds=time.monotonic()-entry['started'], compileCount=stdout.count('... compile middle'),
                       receiptPresent=receipt.exists(), expectedRuntimeAnswer=entry['runtime'],
                       rejection=cause, inventory=self.inventory())
            rows.append(row)
            (args.output / 'receipts.json').write_text(json.dumps(rows, indent=2) + '\n')
            print('PROBE-END', json.dumps({k: v for k, v in row.items() if k != 'inventory'}), flush=True)
            assert observed == status, stderr
            if cause:
                assert cause in stderr and 'BUILD-OK' not in stdout
            else:
                assert ('RUNTIME-OK' if entry['runtime'] is not None else 'BUILD-OK') in stdout, stderr
            if compile_count is not None:
                assert row['compileCount'] == compile_count
            return row

        def close(self):
            # Kill owned groups, including backend descendants after parent exit.
            for entry in self.processes:
                try:
                    os.killpg(entry['process'].pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                entry['process'].wait()

    # Verify that the controlled backend preserves single-writer semantics.
    for writer, value in [('a', 42), ('b', 43)]:
        case = Case('single-' + writer)
        try:
            entry = case.start('build', writer)
            case.captured(entry)
            case.release(writer)
            case.finish(entry, compile_count=1)
            case.finish(case.start('runtime', writer, runtime=value))
        finally:
            case.close()

    for order in [('a', 'b'), ('b', 'a')]:
        case = Case('overlap-' + ''.join(order))
        try:
            a = case.start('a-build', 'a'); case.captured(a)
            b = case.start('b-build', 'b'); case.captured(b)
            entries = dict(a=a, b=b)
            inventories = []
            for writer in order:
                case.release(writer)
                case.finish(entries[writer], status=70 if writer == 'a' else 0,
                            cause='Native build inputs changed' if writer == 'a' else None)
                inventories.append(case.inventory())
                if writer == 'b':
                    case.finish(case.start('runtime-after-b', 'b', runtime=43))
            if order == ('b', 'a'):
                for name in ('middle.native-complete', 'middle.native-source', 'middle.native-interface'):
                    assert inventories[0][name] == inventories[1][name]
                assert any(inventories[0][name] != inventories[1][name] for name in ('middle.o1', 'middle~0.o1'))
            before = case.inventory()
            case.finish(case.start('b-warm', 'b', force=False), compile_count=0)
            assert before == case.inventory()
            case.finish(case.start('final-runtime', 'b', runtime=42 if order == ('b', 'a') else 43))
        finally:
            case.close()

    # A conservative prototype acquires a claim before planning, prevents cleaning
    # while occupied, and retains abandoned claims instead of guessing owner death.
    case = Case('experimental-lease', lease=True)
    busy = 'Native output namespace is busy or abandoned'
    try:
        a = case.start('a-build', 'a'); case.captured(a)
        before = case.inventory()
        case.finish(case.start('b-contended', 'b'), status=70, cause=busy, compile_count=0)
        case.finish(case.start('clean-contended', 'b', clean=True), status=70, cause=busy, compile_count=0)
        assert before == case.inventory()
        assert not list((case.directory / 'b-control').glob('*.ready'))
        case.release('a'); case.finish(a, compile_count=1)
        case.finish(case.start('a-runtime', 'a', runtime=42))
        b = case.start('b-after-release', 'b'); case.captured(b)
        case.release('b'); case.finish(b, compile_count=1)
        case.finish(case.start('b-runtime', 'b', runtime=43))
        case.finish(case.start('clean-after-release', 'b', clean=True))
        assert not any(name.endswith('.o1') or name in
                       ('middle.ssi', 'middle.native-complete', 'middle.native-source', 'middle.native-interface')
                       for name in case.inventory())
    finally:
        case.close()

    case = Case('experimental-abandonment', lease=True)
    try:
        a = case.start('a-build', 'a'); case.captured(a)
        # Terminate just the frontend first: its captured backend jobs still live.
        os.kill(a['process'].pid, signal.SIGKILL)
        observed = a['process'].wait(timeout=args.timeout)
        assert observed == -signal.SIGKILL
        backend_pids = [json.loads(p.read_text())['pid']
                        for p in (case.directory / 'a-control').glob('*.ready')]
        for pid in backend_pids:
            os.kill(pid, 0)
        control = case.directory / 'a-control'
        (control / 'probe-after-owner-death').touch()
        deadline = time.monotonic() + 5
        while {int(p.read_text()) for p in control.glob('*.alive') if p.read_text()} != set(backend_pids):
            if time.monotonic() >= deadline:
                raise TimeoutError('backends did not acknowledge after owner death')
            time.sleep(.01)
        print('BACKENDS-ACKNOWLEDGED-AFTER-OWNER-DEATH', flush=True)
        rows.append(dict(case=case.name, name='owner-killed', exit=observed,
                         capturedBackendsAcknowledgedAfterOwnerDeath=True,
                         receiptPresent=(case.outputs / 'middle.native-complete').exists()))
        case.finish(case.start('b-after-owner-death', 'b'), status=70, cause=busy, compile_count=0)
        lease = case.lib / '.experimental-native-write-lease'
        assert lease.is_dir() and not (case.outputs / 'middle.native-complete').exists()
        # No automatic release/reclamation. Kill the owned backend group before
        # explicit removal of this test-only claim; temporary paths are ours.
        os.killpg(a['process'].pid, signal.SIGKILL)
        deadline = time.monotonic() + 5
        while True:
            remaining = []
            for pid in backend_pids:
                try:
                    os.kill(pid, 0)
                    remaining.append(pid)
                except ProcessLookupError:
                    pass
            if not remaining:
                break
            if time.monotonic() >= deadline:
                raise TimeoutError('owned captured backends did not terminate')
            time.sleep(.01)
        print('CAPTURED-BACKENDS-DEAD', flush=True)
        lease.rmdir()
        b = case.start('b-after-explicit-recovery', 'b'); case.captured(b)
        case.release('b'); case.finish(b, compile_count=1)
        case.finish(case.start('b-runtime', 'b', runtime=43))
    finally:
        case.close()

    report = dict(schema='asp.native-writer-study.v1', identities=identities,
                  experiment='Captured generated Scheme inputs; real gsc -o writes shared native paths',
                  retainedCompilerPatchChanged=False, experimentalLeaseRetained=False,
                  probes=rows)
    (args.output / 'study.json').write_text(json.dumps(report, indent=2) + '\n')
print('WRITER-GAP-REPRODUCED-AND-LEASE-EXPERIMENT-OK', flush=True)
