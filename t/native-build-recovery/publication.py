#!/usr/bin/env python3
"""Bounded research broker: publication epochs and a two-module native closure.

The broker is an advisory, cooperating-writer experiment, not a production
allocator, compiler patch, dependency discoverer, or storage reclamation service.
"""
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text())


def replace(path, value):
    pending = path.with_suffix('.pending')
    pending.write_text(json.dumps(value, indent=2) + '\n')
    pending.replace(path)


@contextmanager
def locked(broker):
    with (broker / 'lock').open('a') as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def grant(broker):
    with locked(broker):
        path = broker / 'authority.json'
        epoch = read(path)['epoch'] + 1 if path.exists() else 1
        replace(path, dict(epoch=epoch, spent=False))
        return epoch


GRAPH = {'app': ['dep'], 'dep': []}
SUFFIXES = ['.ssi', '.o1', '~0.o1', '.native-complete',
            '.native-source', '.native-interface']


def seal(lib):
    files = {}
    for module in GRAPH:
        for suffix in SUFFIXES:
            relative = 'publication/' + module + suffix
            files[relative] = sha(lib / relative)
    return dict(libdir=str(lib), graph=GRAPH, files=files)


def admit(manifest):
    # Explicit fixture graph, not general Gerbil dependency extraction. Installed
    # runtime dependencies remain outside this application-module closure.
    if manifest['graph'] != GRAPH:
        raise ValueError('Incomplete application closure')
    expected = {'publication/' + m + s for m in GRAPH for s in SUFFIXES}
    if set(manifest['files']) != expected:
        raise ValueError('Incomplete artifact inventory')
    lib = Path(manifest['libdir'])
    for relative, digest in manifest['files'].items():
        path = lib / relative
        if not path.is_file() or sha(path) != digest:
            raise ValueError('Artifact digest mismatch: ' + relative)
    return manifest


def publish(broker, token, manifest):
    # All participating grant/publish operations use this same advisory lock.
    # Byte validation assumes completed, quiescent, immutable fixture roots.
    with locked(broker):
        authority = read(broker / 'authority.json')
        if authority['epoch'] != token or authority['spent']:
            raise ValueError('Publication authority superseded or spent')
        admitted = admit(manifest)
        replace(broker / 'active.json', dict(epoch=token, manifest=admitted))
        replace(broker / 'authority.json', dict(epoch=token, spent=True))


def wait_for(predicate, label, timeout=30):
    deadline = time.monotonic() + timeout
    tick = time.monotonic()
    while not predicate():
        if time.monotonic() > deadline:
            raise TimeoutError(label)
        if time.monotonic() - tick > 2:
            print('PROBE-WAIT', label, flush=True)
            tick = time.monotonic()
        time.sleep(.02)


def worker(arguments):
    mode, broker_name, token_text, manifest_name, control_name = arguments
    broker, control = Path(broker_name), Path(control_name)
    token, manifest = int(token_text), read(Path(manifest_name))
    assert read(broker / 'authority.json')['epoch'] == token
    admit(manifest)
    (control / 'checked').touch()
    wait_for(lambda: (control / 'release').exists(), 'old publisher release')
    try:
        if mode == 'unfenced':
            # Intentional counterexample: atomic replace after an earlier check.
            replace(broker / 'active.json', dict(epoch=token, manifest=manifest))
        else:
            publish(broker, token, manifest)
    except ValueError as error:
        print(str(error), flush=True)
        return 70
    print('PUBLISHED', flush=True)
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--make-source', type=Path, required=True)
    parser.add_argument('--patch', type=Path, required=True)
    parser.add_argument('--native-gsc', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    base = args.make_source.read_bytes()
    bases = read(args.patch.parent / 'patch-bases.json')
    assert hashlib.sha256(base).hexdigest() == bases['installed']['sourceSha256']
    assert args.native_gsc.is_file() and os.access(args.native_gsc, os.X_OK)
    observations = []

    def mark(name, **fields):
        row = dict(name=name, **fields)
        observations.append(row)
        replace(args.output / 'observations.json', observations)
        print('PROBE-END', json.dumps(row), flush=True)

    with tempfile.TemporaryDirectory(prefix='gerbil-publication-study-') as temporary:
        root = Path(temporary).resolve()
        source = root / 'native-make.ss'
        source.write_bytes(base)
        subprocess.run(['patch', '-f', str(source)], input=args.patch.read_text(),
                       text=True, capture_output=True, check=True)
        patched_hash = sha(source)
        libs = {}

        def environment(lib):
            env = dict(os.environ, GERBIL_PATH=str(root / 'runtime'),
                       GERBIL_LOADPATH=str(lib), GERBIL_GSC=str(args.native_gsc.resolve()),
                       GERBIL_BUILD_CORES='2')
            for key in ['SDKROOT', 'DEVELOPER_DIR']:
                env.pop(key, None)
            return env

        def run(name, expression, loadpath, expected=0, marker='RUNTIME-OK', answer=None):
            print('PROBE-START', name, flush=True)
            out, err = args.output / (name + '.out'), args.output / (name + '.err')
            with out.open('w') as stdout, err.open('w') as stderr:
                proc = subprocess.Popen(['gxi', '-e', expression], env=environment(loadpath),
                                        stdout=stdout, stderr=stderr, start_new_session=True)
            try:
                wait_for(lambda: proc.poll() is not None, name, timeout=40)
            finally:
                if proc.poll() is None:
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            assert proc.returncode == expected, out.read_text() + err.read_text()
            assert marker in out.read_text() + err.read_text(), err.read_text()
            mark(name, exit=proc.returncode, marker=marker, expectedAnswer=answer,
                 stdoutSha256=sha(out), stderrSha256=sha(err))

        def runtime(name, lib, answer):
            run(name, '(import :publication/app) '
                f'(unless (= answer {answer}) (error "Wrong answer" answer)) '
                '(displayln "RUNTIME-OK")', lib, answer=answer)

        for generation, value in [('a', 1), ('b', 2), ('fallback', 60)]:
            src, lib = root / ('src-' + generation), root / ('lib-' + generation)
            src.mkdir(); lib.mkdir(); libs[generation] = lib
            (src / 'gerbil.pkg').write_text('(package: publication)\n')
            (src / 'dep.ss').write_text(f'(export value)\n(def value {value})\n')
            (src / 'app.ss').write_text('(import :publication/dep)\n(export answer)\n(def answer (+ 41 value))\n')
            spec = '["dep" "app"]' if generation != 'fallback' else '["dep"]'
            expression = '(import ' + json.dumps(str(source)) + ') '
            expression += '(with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () '
            expression += '(make ' + spec + ' srcdir: ' + json.dumps(str(src))
            expression += ' libdir: ' + json.dumps(str(lib)) + ' parallelize: 2 force: #t) (displayln "BUILD-OK")))'
            run('build-' + generation, expression, lib, marker='BUILD-OK')
        runtime('generation-a-runtime', libs['a'], 42)
        runtime('generation-b-runtime', libs['b'], 43)
        manifests = {key: seal(libs[key]) for key in ['a', 'b']}
        for key, manifest in manifests.items():
            replace(root / (key + '.json'), manifest)
            replace(args.output / (key + '-manifest.json'), manifest)

        partial = root / 'partial'; shutil.copytree(libs['b'], partial)
        for path in (partial / 'publication').glob('dep*'):
            path.unlink()
        assert (partial / 'publication/app.native-complete').is_file()
        # An explicit fallback dependency root permits import success with the
        # wrong dependency value even though the entry module has a receipt.
        runtime('partial-root-with-fallback', str(partial) + os.pathsep + str(libs['fallback']), 101)
        incomplete = dict(manifests['b'], libdir=str(partial), graph={'app': ['dep']})
        broker = root / 'closure-broker'; broker.mkdir()
        token = grant(broker); publish(broker, token, manifests['a'])
        before = sha(broker / 'active.json')

        def reject(name, manifest, cause):
            token = grant(broker)
            try:
                publish(broker, token, manifest)
            except ValueError as error:
                assert cause in str(error), error
                assert before == sha(broker / 'active.json')
                mark(name, cause=str(error), activeSelectorUnchanged=True)
            else:
                raise AssertionError('Unexpected admission')

        reject('missing-closure-node-rejected', incomplete, 'Incomplete application closure')
        reject('missing-dependency-artifacts-rejected', dict(manifests['b'], libdir=str(partial)), 'Artifact digest mismatch')
        incomplete_inventory = dict(manifests['b'], files={k: v for k, v in manifests['b']['files'].items() if '/dep' not in k})
        reject('missing-inventory-rejected', incomplete_inventory, 'Incomplete artifact inventory')
        tampered = root / 'tampered'; shutil.copytree(libs['b'], tampered)
        with (tampered / 'publication/dep.o1').open('ab') as handle:
            handle.write(b'changed-after-seal')
        reject('dependency-byte-change-rejected', dict(manifests['b'], libdir=str(tampered)), 'Artifact digest mismatch')
        token = grant(broker); publish(broker, token, manifests['b'])
        active = read(broker / 'active.json')
        runtime('admitted-closure-runtime', active['manifest']['libdir'], 43)
        try:
            publish(broker, token, manifests['a'])
        except ValueError as error:
            mark('spent-token-rejected', cause=str(error))
        else:
            raise AssertionError('Spent token accepted')

        for mode in ['unfenced', 'fenced']:
            broker = root / mode; broker.mkdir()
            control = root / (mode + '-control'); control.mkdir()
            old_token = grant(broker)
            out, err = args.output / (mode + '.out'), args.output / (mode + '.err')
            with out.open('w') as stdout, err.open('w') as stderr:
                old = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), '--worker', mode,
                                        str(broker), str(old_token), str(root / 'a.json'), str(control)],
                                       stdout=stdout, stderr=stderr, start_new_session=True)
            try:
                wait_for(lambda: (control / 'checked').exists(), 'old publisher checked')
                new_token = grant(broker); publish(broker, new_token, manifests['b'])
                pinned = read(broker / 'active.json')['manifest']['libdir']
                runtime(mode + '-new-before-release', pinned, 43)
                before = sha(broker / 'active.json')
                (control / 'release').touch()
                wait_for(lambda: old.poll() is not None, 'old publisher exit')
                assert old.returncode == (0 if mode == 'unfenced' else 70), err.read_text()
                current = read(broker / 'active.json')
                assert current['epoch'] == (old_token if mode == 'unfenced' else new_token)
                assert (before == sha(broker / 'active.json')) == (mode == 'fenced')
                mark(mode + '-stale-publisher', exit=old.returncode, oldToken=old_token,
                     newToken=new_token, activeToken=current['epoch'], selectorUnchanged=mode == 'fenced',
                     stdoutSha256=sha(out), stderrSha256=sha(err))
                runtime(mode + '-fresh-reader-after-release', current['manifest']['libdir'],
                        42 if mode == 'unfenced' else 43)
                runtime(mode + '-pinned-reader-after-release', pinned, 43)
            finally:
                if old.poll() is None:
                    os.killpg(old.pid, signal.SIGKILL)
                old.wait()
        replace(args.output / 'study.json', dict(schema='asp.native-publication-study.v1',
                patchedSourceSha256=patched_hash, patchSha256=sha(args.patch),
                nativeGscSha256=sha(args.native_gsc), runnerSha256=sha(Path(__file__)),
                observations=observations, retainedCompilerPatchChanged=False))
    print('PUBLICATION-FENCING-AND-APPLICATION-CLOSURE-STUDIED', flush=True)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--worker':
        sys.exit(worker(sys.argv[2:]))
    main()
