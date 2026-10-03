#!/usr/bin/env python3
"""Exercise native std/make completion in an isolated package (12 build cores)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--make-source', type=Path, required=True)
parser.add_argument('--patch', type=Path)
parser.add_argument('--output', type=Path, required=True)
modes = parser.add_mutually_exclusive_group()
modes.add_argument('--only-interruption', action='store_true')
modes.add_argument('--only-receipt-integrity', action='store_true')
modes.add_argument('--only-input-identity', action='store_true',
                   help='Reproduce the legacy v1 mtime gap; requires a legacy make source')
modes.add_argument('--qualify-input-identity', action='store_true')
modes.add_argument('--only-warm-cost', action='store_true')
modes.add_argument('--only-snapshot-contract', action='store_true')
modes.add_argument('--qualify-live-inputs', action='store_true')
modes.add_argument('--reproduce-live-input-gap', action='store_true')
parser.add_argument('--native-gsc', type=Path)
parser.add_argument('--fixture-padding-bytes', type=int, default=0)
parser.add_argument('--migration-source', type=Path)
parser.add_argument('--timeout', type=float, default=180)
args = parser.parse_args()
if args.fixture_padding_bytes < 0:
    parser.error('fixture padding must be nonnegative')
if args.migration_source and not args.only_snapshot_contract:
    parser.error('migration source requires the snapshot contract mode')
if args.qualify_live_inputs or args.reproduce_live_input_gap:
    if not args.native_gsc or not args.native_gsc.is_file() or not os.access(args.native_gsc, os.X_OK):
        parser.error('live input probes require an explicit executable native gsc')
source = args.make_source.resolve()
args.output.mkdir(parents=True, exist_ok=True)
receipts = []
with tempfile.TemporaryDirectory(prefix='gerbil-native-recovery-') as directory:
    root = Path(directory)
    if args.patch:
        patch = args.patch.resolve()
        bases = json.loads((patch.parent / 'patch-bases.json').read_text())
        base = bases[patch.name.split('-')[0]]
        actual = hashlib.sha256(source.read_bytes()).hexdigest()
        assert actual == base['sourceSha256'], f'patch base mismatch: {actual}'
        patched = root / 'native-make.ss'
        patched.write_bytes(source.read_bytes())
        result = subprocess.run(['patch', '-f', str(patched)], input=patch.read_text(),
                                text=True, capture_output=True, check=True)
        print(result.stdout, flush=True)
        source = patched
    (root / 'gerbil.pkg').write_text('(package: native-recovery)\n')
    (root / 'middle.ss').write_text('''(export answer inner empty)
(module inner (export value) (def value 42))
(module empty (export))
(import inner)
(begin-syntax (def marker 1))
(defsyntax (identity stx) (syntax-case stx () ((_ x) #'x)))
(def answer (identity value))
''')
    if args.fixture_padding_bytes:
        line = b';' + b'x' * 78 + b'\n'
        whole, tail = divmod(args.fixture_padding_bytes, len(line))
        fixture_source = root / 'middle.ss'
        fixture_source.write_bytes(fixture_source.read_bytes() + line * whole + b'\n' * tail)
    lib = root / 'lib'
    outputs = lib / 'native-recovery'
    completion = outputs / 'middle.native-complete'

    def snapshot():
        return {str(p.relative_to(lib)): (p.stat().st_mtime_ns, p.stat().st_size)
                for p in lib.rglob('*') if p.is_file()}

    def run(name, *, force=False, failure=False, debug=False, clean=False, runtime=False, interrupt=False, expected_answer=42, input_change=None, reuse_backend=False, expected_rejection=False):
        spec = '[gxc: "middle" "-cc-options" "-fasp-native-failure"]' if failure else '"middle"'
        if runtime:
            expression = ('(import :native-recovery/middle) (unless (= answer ' + str(expected_answer) + ') (error "wrong runtime value")) (displayln "RUNTIME-OK")')
        else:
            expression = ('(import ' + json.dumps(str(source)) + ')\n' +
                          ('(make-clean ' if clean else '(make ') + '[' + spec + ']' +
                          ' srcdir: ' + json.dumps(str(root)) +
                          ' libdir: ' + json.dumps(str(lib)) +
                          ' bindir: ' + json.dumps(str(root / 'bin')) +
                          ('' if clean else ' parallelize: 12 force: ' + ('#t' if force else '#f') +
                           ' debug: ' + ('#t' if debug else '#f')) +
                          ') (displayln "NATIVE-COMPLETE-OK")')
        imports, body = expression.split('\n', 1) if '\n' in expression else expression.split(') ', 1)
        if '\n' not in expression:
            imports += ')'
        expression = (imports + '\n(with-catch (lambda (failure) (display-exception failure (current-error-port)) (exit 70)) (lambda () ' + body + '))')
        command = ['gerbil', 'interactive', '-e', expression]
        env = dict(os.environ, GERBIL_BUILD_CORES='12', GERBIL_PATH=str(root), GERBIL_LOADPATH=str(lib))
        marker = root / 'backend-started'
        release = root / 'backend-release'
        if input_change:
            marker.unlink(missing_ok=True)
            release.unlink(missing_ok=True)
            backend = root / 'blocked-gsc'
            backend.write_text('#!' + sys.executable + '\n' +
                               'from pathlib import Path\nimport os, sys, time\n' +
                               'Path(' + repr(str(marker)) + ').write_text("started")\n' +
                               'while not Path(' + repr(str(release)) + ').exists(): time.sleep(0.01)\n' +
                               'os.execv(' + repr(str(args.native_gsc.resolve())) + ', [' + repr(str(args.native_gsc.resolve())) + ', *sys.argv[1:]])\n')
            backend.chmod(0o700)
            env['GERBIL_GSC'] = str(backend)
        if reuse_backend:
            env['GERBIL_GSC'] = str(root / 'blocked-gsc')
        if interrupt:
            if marker.exists():
                marker.unlink()
            backend = root / 'blocked-gsc'
            backend.write_text('#!' + sys.executable + '\n' +
                               'from pathlib import Path\nimport time\n' +
                               'Path(' + repr(str(marker)) + ').write_text("started")\n' +
                               'while True: time.sleep(1)\n')
            backend.chmod(0o700)
            env['GERBIL_GSC'] = str(backend)
        interface_witness = outputs / "middle.native-interface"
        previous_witness = interface_witness.stat().st_mtime_ns if interface_witness.exists() else None
        started = time.monotonic()
        before = resource.getrusage(resource.RUSAGE_CHILDREN)
        print(f'PROBE-START {name}', flush=True)
        with (args.output / (name + '.out')).open('w') as out, (args.output / (name + '.err')).open('w') as err:
            proc = subprocess.Popen(command, env=env, stdout=out, stderr=err, start_new_session=True)
            expired = False
            try:
                if interrupt or input_change:
                    # A controlled gsc subprocess acknowledges that a backend
                    # job is running. Compiler stdout is buffered, so it cannot
                    # serve as a reliable interruption boundary.
                    while not marker.exists():
                        if proc.poll() is not None:
                            raise AssertionError('backend exited before interruption point')
                        if time.monotonic() - started >= args.timeout:
                            raise subprocess.TimeoutExpired(command, args.timeout)
                        time.sleep(0.01)
                    if interrupt:
                        os.killpg(proc.pid, signal.SIGTERM)
                    else:
                        if input_change == 'interface':
                            # Backend launch can precede frontend completion. Wait
                            # for this build's interface witness, not the old SSI.
                            while not (interface_witness.exists()
                                       and interface_witness.stat().st_mtime_ns != previous_witness
                                       and interface_witness.read_bytes() == (outputs / 'middle.ssi').read_bytes()):
                                if proc.poll() is not None:
                                    raise AssertionError('build exited before interface capture')
                                if time.monotonic() - started >= args.timeout:
                                    raise subprocess.TimeoutExpired(command, args.timeout)
                                time.sleep(0.01)
                        changed = root / 'middle.ss'  if input_change == 'source' else outputs / 'middle.ssi'
                        prior = changed.stat()
                        data = changed.read_bytes()
                        changed.write_bytes(data.replace(b'(def value 42)', b'(def value 43)') if input_change == 'source' else data + b'\n; changed during backend compilation\n')
                        os.utime(changed, ns=(prior.st_atime_ns, prior.st_mtime_ns))
                        assert changed.stat().st_mtime_ns == prior.st_mtime_ns
                        release.write_text('release')
                status = proc.wait(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                expired = True
                os.killpg(proc.pid, signal.SIGTERM)
                try:
                    status = proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid, signal.SIGKILL)
                    status = proc.wait()
        after = resource.getrusage(resource.RUSAGE_CHILDREN)
        stdout = (args.output / (name + '.out')).read_text()
        stderr = (args.output / (name + '.err')).read_text()
        row = dict(name=name, exit=status, timeout=expired, cores=12,
                   wallSeconds=time.monotonic()-started,
                   userSeconds=after.ru_utime-before.ru_utime,
                   systemSeconds=after.ru_stime-before.ru_stime,
                   compileCount=stdout.count('... compile middle'),
                   sourceBytes=(root / 'middle.ss').stat().st_size,
                   interfaceBytes=(outputs / 'middle.ssi').stat().st_size if (outputs / 'middle.ssi').exists() else None,
                   snapshotBytes=sum(p.stat().st_size for p in
                                     (outputs / 'middle.native-source', outputs / 'middle.native-interface')
                                     if p.exists()),
                   receiptBytes=completion.stat().st_size if completion.exists() else None,
                   expectedRuntimeAnswer=expected_answer if runtime else None,
                   inputChange=input_change, inputMtimePreserved=bool(input_change),
                   interfaceCaptureAcknowledged=input_change == 'interface')
        receipts.append(row)
        (args.output / 'receipts.json').write_text(json.dumps(receipts, indent=2) + '\n')
        print('PROBE-END ' + json.dumps(row), flush=True)
        assert not expired, f'{name}: timed out'
        if expected_rejection:
            assert status == 70 and not completion.exists(), 'live change did not reject publication'
            assert 'Native build inputs changed' in stderr, 'failure was not the input guard'
        elif failure or interrupt:
            assert status != 0 and not completion.exists(), f'{name}: failure published a receipt'
        else:
            assert status == 0, f'{name}: {stderr}'
            assert ('RUNTIME-OK' if runtime else 'NATIVE-COMPLETE-OK') in stdout
            if not runtime and not clean:
                assert completion.exists(), f'{name}: missing completion receipt'
        return row

    if args.reproduce_live_input_gap:
        run('cold')
        run('source-change-during-backend', force=True, input_change='source')
        assert run('wrong-warm-reuse', reuse_backend=True)['compileCount'] == 0
        run('stale-runtime', runtime=True, expected_answer=42)
    elif args.qualify_live_inputs:
        run('cold')
        run('source-change-during-backend', force=True, input_change='source', expected_rejection=True)
        assert run('source-change-recovery', reuse_backend=True)['compileCount'] == 1
        run('source-change-runtime', runtime=True, expected_answer=43)
        before = snapshot()
        assert run('source-change-warm', reuse_backend=True)['compileCount'] == 0
        assert snapshot() == before
        run('interface-change-during-backend', force=True, input_change='interface', expected_rejection=True)
        assert run('interface-change-recovery', reuse_backend=True)['compileCount'] == 1
        run('interface-change-runtime', runtime=True, expected_answer=43)
        before = snapshot()
        assert run('interface-change-warm', reuse_backend=True)['compileCount'] == 0
        assert snapshot() == before
    elif args.only_snapshot_contract:
        if args.migration_source:
            current_source = source
            source = args.migration_source.resolve()
            run('legacy-cold')
            source = current_source
            assert run('legacy-migration')['compileCount'] == 1
        else:
            run('cold')
        assert run('warm')['compileCount'] == 0
        witnesses = [outputs / 'middle.native-source', outputs / 'middle.native-interface']
        assert all(p.exists() for p in witnesses), 'missing binary snapshots'
        for witness in witnesses:
            witness.unlink()
            assert run('missing-' + witness.name)['compileCount'] == 1
        for witness in witnesses:
            old_stat = witness.stat()
            data = witness.read_bytes()
            witness.write_bytes(bytes([data[0] ^ 1]) + data[1:])
            os.utime(witness, ns=(old_stat.st_atime_ns, old_stat.st_mtime_ns))
            assert run('corrupt-' + witness.name)['compileCount'] == 1
        before = snapshot()
        assert run('snapshot-warm')['compileCount'] == 0
        assert snapshot() == before, 'snapshot warm build wrote outputs'
        run('runtime', runtime=True)
        run('clean', clean=True)
        assert not any(p.exists() for p in witnesses), 'clean retained binary snapshots'
    elif args.only_warm_cost:
        run('cold')
        before = snapshot()
        for attempt in range(3):
            assert run('warm-' + str(attempt))['compileCount'] == 0
        assert snapshot() == before, 'warm cost probe wrote outputs'
    elif args.only_input_identity or args.qualify_input_identity:
        expected_compile = 1 if args.qualify_input_identity else 0
        expected_value = 43 if args.qualify_input_identity else 42
        run('cold')
        assert run('warm')['compileCount'] == 0
        source_file = root / 'middle.ss'
        old_stat = source_file.stat()
        source_file.write_text(source_file.read_text().replace('(def value 42)', '(def value 43)'))
        os.utime(source_file, ns=(old_stat.st_atime_ns, old_stat.st_mtime_ns))
        assert source_file.stat().st_mtime_ns == old_stat.st_mtime_ns
        assert run('same-mtime-source')['compileCount'] == expected_compile, 'source identity result differs from selected mode'
        run('changed-runtime', runtime=True, expected_answer=expected_value)
        ssi = outputs / 'middle.ssi'
        old_stat = ssi.stat()
        ssi.write_text(ssi.read_text() + '\n; changed interface bytes\n')
        os.utime(ssi, ns=(old_stat.st_atime_ns, old_stat.st_mtime_ns))
        assert ssi.stat().st_mtime_ns == old_stat.st_mtime_ns
        assert run('same-mtime-interface')['compileCount'] == expected_compile, 'SSI identity result differs from selected mode'
        before = snapshot()
        assert run('identity-warm')['compileCount'] == 0
        assert snapshot() == before, 'identity warm build wrote outputs'
        run('identity-runtime', runtime=True, expected_answer=expected_value)
    elif args.only_receipt_integrity:
        run('cold')
        assert run('warm')['compileCount'] == 0
        completion.write_text(completion.read_text() + '\n(extra-record)\n')
        assert run('trailing-record')['compileCount'] == 1, 'accepted trailing receipt data'
        completion.write_text(completion.read_text() + '\n(unclosed\n')
        assert run('trailing-reader-error')['compileCount'] == 1, 'accepted malformed receipt tail'
        before = snapshot()
        assert run('integrity-warm')['compileCount'] == 0
        assert snapshot() == before, 'integrity warm build wrote outputs'
        run('runtime', runtime=True)
    elif args.only_interruption:
        run('cold')
        run('interrupted-backend', force=True, interrupt=True)
        assert run('interruption-recovery')['compileCount'] == 1
        run('runtime', runtime=True)
    else:
        run('cold')
        before = snapshot()
        assert run('warm')['compileCount'] == 0
        assert snapshot() == before, 'warm build wrote outputs'
        for part in ('middle.o1', 'middle~0.o1', 'middle~1.o1',
                     'middle~inner.o1', 'middle~empty.o1', 'middle~inner~0.o1'):
            (outputs / part).unlink()
            scm = outputs / (part[:-3] + '.scm')
            if scm.exists():
                scm.unlink()
            assert run('missing-' + part)['compileCount'] == 1
            assert (outputs / part).exists(), part
        assert run('force', force=True)['compileCount'] == 1
        assert run('post-force-warm')['compileCount'] == 0
        assert run('debug-option', debug=True)['compileCount'] == 1
        assert run('post-debug-warm', debug=True)['compileCount'] == 0
        completion.write_text('(corrupt)\n')
        assert run('corrupt-receipt', debug=True)['compileCount'] == 1
        run('backend-failure', failure=True, force=True)
        assert run('failure-recovery')['compileCount'] == 1
        run('runtime', runtime=True)
        neighbor = outputs / 'middle-neighbor.o1'
        neighbor.write_text('preserve this unrelated output\n')
        run('clean', clean=True)
        assert neighbor.exists(), 'clean removed a neighboring module'
        assert not completion.exists(), 'clean retained a completion receipt'
        assert not (outputs / 'middle~empty.o1').exists(), 'clean retained a nested loader'
print('KNOWN-IDENTITY-GAP-REPRODUCED' if args.only_input_identity
      else 'LIVE-INPUT-GAP-REPRODUCED' if args.reproduce_live_input_gap
      else 'LIVE-INPUT-GUARD-SUITE-OK' if args.qualify_live_inputs
      else 'CONTENT-IDENTITY-SUITE-OK' if args.qualify_input_identity
      else 'SNAPSHOT-CONTRACT-SUITE-OK' if args.only_snapshot_contract
      else 'WARM-COST-PROBES-OK' if args.only_warm_cost
      else 'RECOVERY-SUITE-OK', flush=True)
