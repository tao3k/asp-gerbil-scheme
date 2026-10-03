#!/usr/bin/env python3
"""SIGKILL controls for split publication state and a single-record broker.

This is cooperating-writer research on a local filesystem. It does not simulate
power loss or implement production generation storage or general closure discovery.
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

import publication as previous


SCHEMA = 'asp.publication-transaction-study.v1'


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def state(broker):
    value = previous.read(broker / 'state.json')
    if (not isinstance(value, dict) or set(value) != {'schema', 'epoch', 'spent', 'active'}
            or value['schema'] != SCHEMA or type(value['epoch']) is not int
            or value['epoch'] < 0 or type(value['spent']) is not bool):
        raise ValueError('Invalid transaction state')
    active = value['active']
    if active is not None:
        if (not isinstance(active, dict) or set(active) != {'epoch', 'request', 'manifest', 'digest'}
                or type(active['epoch']) is not int or not 0 < active['epoch'] <= value['epoch']
                or not isinstance(active['request'], str) or not active['request']
                or active['digest'] != digest(active['manifest'])):
            raise ValueError('Invalid active publication')
    if ((value['spent'] and (active is None or active['epoch'] != value['epoch']))
            or (not value['spent'] and active is not None and active['epoch'] == value['epoch'])):
        raise ValueError('Inconsistent authority and selector')
    return value


def commit(broker, value, checkpoint=lambda stage: None):
    checkpoint('before-stage')
    # A unique abandoned staging file is never read as authoritative state.
    fd, staging = tempfile.mkstemp(prefix='state-', suffix='.pending', dir=broker)
    with os.fdopen(fd, 'w') as handle:
        handle.write(json.dumps(value, indent=2) + '\n')
        handle.flush()
        os.fsync(handle.fileno())
    checkpoint('stage-synced')
    os.replace(staging, broker / 'state.json')
    checkpoint('replaced')
    directory = os.open(broker, os.O_RDONLY)
    try:
        os.fsync(directory)
    finally:
        os.close(directory)
    checkpoint('directory-synced')


def grant(broker):
    with previous.locked(broker):
        value = state(broker)  # Missing/corrupt state is not reset automatically.
        value.update(epoch=value['epoch'] + 1, spent=False)
        commit(broker, value)
        return value['epoch']


def publish(broker, token, request, manifest, checkpoint=lambda stage: None,
            admission=previous.admit):
    with previous.locked(broker):
        value = state(broker)
        if token != value['epoch']:
            raise ValueError('Publication authority superseded')
        active = value['active']
        if value['spent']:
            if active['request'] == request and active['digest'] == digest(manifest):
                return 'ACK-REPLAY'
            raise ValueError('Consumed token request mismatch')
        admission(manifest)
        value.update(spent=True, active=dict(epoch=token, request=request,
                                            manifest=manifest, digest=digest(manifest)))
        commit(broker, value, checkpoint)
        return 'ACK-COMMITTED'


def worker(arguments):
    mode, broker_name, token_text, request, manifest_name, stage, control_name = arguments
    broker, control = Path(broker_name), Path(control_name)
    token, manifest = int(token_text), previous.read(Path(manifest_name))

    def checkpoint(current):
        if current == stage:
            (control / 'paused').write_text(current)
            previous.wait_for(lambda: (control / 'release').exists(), current)

    try:
        if mode == 'split':
            with previous.locked(broker):
                authority = previous.read(broker / 'authority.json')
                if authority['epoch'] != token or authority['spent']:
                    raise ValueError('Publication authority superseded or spent')
                previous.admit(manifest)
                previous.replace(broker / 'active.json', dict(epoch=token, manifest=manifest))
                checkpoint('selector-replaced')
                previous.replace(broker / 'authority.json', dict(epoch=token, spent=True))
            result = 'ACK-SPLIT'
        else:
            result = publish(broker, token, request, manifest, checkpoint)
        print(result, flush=True)
        return 0
    except (ValueError, OSError) as error:
        print(type(error).__name__ + ': ' + str(error), flush=True)
        return 70


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--make-source', type=Path, required=True)
    parser.add_argument('--patch', type=Path, required=True)
    parser.add_argument('--native-gsc', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    assert previous.sha(args.make_source) == previous.read(args.patch.parent / 'patch-bases.json')['installed']['sourceSha256']
    assert args.native_gsc.is_file() and os.access(args.native_gsc, os.X_OK)
    observations = []

    def mark(name, **fields):
        row = dict(name=name, **fields); observations.append(row)
        previous.replace(args.output / 'observations.json', observations)
        print('PROBE-END', json.dumps(row), flush=True)

    with tempfile.TemporaryDirectory(prefix='gerbil-publication-crash-') as temporary:
        root = Path(temporary).resolve()
        source = root / 'native-make.ss'; source.write_bytes(args.make_source.read_bytes())
        subprocess.run(['patch', '-f', str(source)], input=args.patch.read_text(),
                       text=True, capture_output=True, check=True)
        patched_hash = previous.sha(source)
        manifests = {}

        def run(name, command, env=None, expected=0, marker=None, answer=None):
            print('PROBE-START', name, flush=True)
            out, err = args.output / (name + '.out'), args.output / (name + '.err')
            with out.open('w') as stdout, err.open('w') as stderr:
                proc = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
            try:
                previous.wait_for(lambda: proc.poll() is not None, name, timeout=40)
            finally:
                if proc.poll() is None:
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            assert proc.returncode == expected, out.read_text() + err.read_text()
            if marker:
                assert marker in out.read_text(), out.read_text() + err.read_text()
            mark(name, exit=proc.returncode, marker=marker, expectedAnswer=answer,
                 stdoutSha256=previous.sha(out), stderrSha256=previous.sha(err))

        def environment(lib):
            env = dict(os.environ, GERBIL_PATH=str(root / 'runtime'), GERBIL_LOADPATH=str(lib),
                       GERBIL_GSC=str(args.native_gsc.resolve()), GERBIL_BUILD_CORES='2')
            for key in ['SDKROOT', 'DEVELOPER_DIR']:
                env.pop(key, None)
            return env

        def runtime(name, manifest, answer):
            expression = '(import :publication/app) ' + f'(unless (= answer {answer}) (error "Wrong answer" answer)) (displayln "RUNTIME-OK")'
            run(name, ['gxi', '-e', expression], environment(manifest['libdir']), marker='RUNTIME-OK', answer=answer)

        for key, value in [('a', 1), ('b', 2)]:
            src, lib = root / ('src-' + key), root / ('lib-' + key)
            src.mkdir(); lib.mkdir()
            (src / 'gerbil.pkg').write_text('(package: publication)\n')
            (src / 'dep.ss').write_text(f'(export value)\n(def value {value})\n')
            (src / 'app.ss').write_text('(import :publication/dep)\n(export answer)\n(def answer (+ 41 value))\n')
            expression = '(import ' + json.dumps(str(source)) + ') (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () '
            expression += '(make ["dep" "app"] srcdir: ' + json.dumps(str(src)) + ' libdir: ' + json.dumps(str(lib)) + ' parallelize: 2 force: #t) (displayln "BUILD-OK")))'
            run('build-' + key, ['gxi', '-e', expression], environment(lib), marker='BUILD-OK')
            manifests[key] = previous.seal(lib)
            previous.replace(root / (key + '.json'), manifests[key])

        def worker_command(mode, broker, token, key, request='publish-b', stage='none', control=None):
            return [sys.executable, str(Path(__file__).resolve()), '--worker', mode, str(broker),
                    str(token), request, str(root / (key + '.json')), stage, str(control or root)]

        def kill_at(name, command, control):
            out, err = args.output / (name + '.out'), args.output / (name + '.err')
            print('PROBE-START', name, flush=True)
            with out.open('w') as stdout, err.open('w') as stderr:
                proc = subprocess.Popen(command, stdout=stdout, stderr=stderr, start_new_session=True)
            try:
                previous.wait_for(lambda: (control / 'paused').exists(), name)
                stage = (control / 'paused').read_text()
                os.killpg(proc.pid, signal.SIGKILL)
                assert proc.wait(timeout=5) == -signal.SIGKILL
                mark(name, stage=stage, exit=-signal.SIGKILL,
                     stdoutSha256=previous.sha(out), stderrSha256=previous.sha(err))
            finally:
                if proc.poll() is None:
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()

        broker = root / 'split'; broker.mkdir()
        first = previous.grant(broker); previous.publish(broker, first, manifests['a'])
        token = previous.grant(broker)
        control = root / 'split-control'; control.mkdir()
        kill_at('split-killed-between-records', worker_command('split', broker, token, 'b', stage='selector-replaced', control=control), control)
        assert not previous.read(broker / 'authority.json')['spent']
        assert previous.read(broker / 'active.json')['epoch'] == token
        mark('split-restarted-state', selectorEpoch=token, tokenSpent=False)
        runtime('split-before-replay', previous.read(broker / 'active.json')['manifest'], 43)
        run('split-replay-different-manifest', worker_command('split', broker, token, 'a'), marker='ACK-SPLIT')
        runtime('split-after-replay', previous.read(broker / 'active.json')['manifest'], 42)

        for stage in ['before-stage', 'stage-synced', 'replaced', 'directory-synced']:
            broker = root / stage; broker.mkdir()
            commit(broker, dict(schema=SCHEMA, epoch=0, spent=False, active=None))
            first = grant(broker); publish(broker, first, 'publish-a', manifests['a'])
            token = grant(broker)
            before = previous.sha(broker / 'state.json')
            control = root / (stage + '-control'); control.mkdir()
            kill_at(stage + '-killed', worker_command('transaction', broker, token, 'b', stage=stage, control=control), control)
            value = state(broker)
            committed = stage in ['replaced', 'directory-synced']
            assert value['spent'] == committed
            assert value['active']['epoch'] == (token if committed else first)
            assert (previous.sha(broker / 'state.json') == before) == (not committed)
            mark(stage + '-restarted-state', epoch=value['epoch'], spent=value['spent'],
                 activeEpoch=value['active']['epoch'], abandonedStagingFiles=len(list(broker.glob('*.pending'))))
            runtime(stage + '-runtime-before-retry', value['active']['manifest'], 43 if committed else 42)
            state_hash = previous.sha(broker / 'state.json')
            run(stage + '-same-request-retry', worker_command('transaction', broker, token, 'b'),
                marker='ACK-REPLAY' if committed else 'ACK-COMMITTED')
            if committed:
                assert state_hash == previous.sha(broker / 'state.json')
            state_hash = previous.sha(broker / 'state.json')
            run(stage + '-different-manifest-rejected', worker_command('transaction', broker, token, 'a'),
                expected=70, marker='Consumed token request mismatch')
            run(stage + '-different-request-rejected', worker_command('transaction', broker, token, 'b', request='other-request'),
                expected=70, marker='Consumed token request mismatch')
            assert state_hash == previous.sha(broker / 'state.json')
            runtime(stage + '-runtime-after-retry', state(broker)['active']['manifest'], 43)
            newer = grant(broker)
            run(stage + '-superseded-token-rejected', worker_command('transaction', broker, token, 'b'),
                expected=70, marker='Publication authority superseded')
            assert newer == token + 1

        for failure in ['missing', 'malformed', 'inconsistent']:
            broker = root / failure; broker.mkdir()
            if failure == 'malformed':
                (broker / 'state.json').write_text('{')
            elif failure == 'inconsistent':
                previous.replace(broker / 'state.json', dict(schema=SCHEMA, epoch=2, spent=True, active=None))
            before = previous.sha(broker / 'state.json') if (broker / 'state.json').exists() else None
            run(failure + '-state-rejected', worker_command('transaction', broker, 2, 'b'), expected=70,
                marker={'missing':'FileNotFoundError', 'malformed':'JSONDecodeError', 'inconsistent':'Inconsistent authority and selector'}[failure])
            after = previous.sha(broker / 'state.json') if (broker / 'state.json').exists() else None
            assert before == after
            mark(failure + '-state-preserved', authoritativeFileUnchanged=True)
        previous.replace(args.output / 'study.json', dict(schema='asp.native-publication-crash-study.v1',
                         patchedSourceSha256=patched_hash, patchSha256=previous.sha(args.patch),
                         nativeGscSha256=previous.sha(args.native_gsc), runnerSha256=previous.sha(Path(__file__)),
                         sharedHarnessSha256=previous.sha(Path(previous.__file__)),
                         retainedCompilerPatchChanged=False, observations=observations, manifests=manifests))
    print('PUBLICATION-PROCESS-CRASH-TRANSACTION-STUDIED', flush=True)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--worker':
        sys.exit(worker(sys.argv[2:]))
    main()
