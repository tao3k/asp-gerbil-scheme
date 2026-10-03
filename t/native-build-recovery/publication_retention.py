#!/usr/bin/env python3
"""Cooperating reader retention and explicit writer-quiescence research controls.

Only the study's declared scratch generation roots can be collected. No PID/TTL
recovery, authenticated ownership, or production collection service is provided.
"""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import uuid

import publication as files
import publication_admission as admission
import publication_crash as transaction


def root_of(subject):
    return str(Path(subject['manifest']['libdir']).resolve())


def registry(broker):
    return files.read(broker / 'retention.json')


def generation(broker, libdir):
    value = registry(broker)
    root = str(Path(libdir).resolve())
    if root not in value['generations']:
        raise ValueError('Generation not owned by this study')
    return value, root, value['generations'][root]


def admissible(broker, subject):
    _, _, status = generation(broker, root_of(subject))
    if status['retired']:
        raise ValueError('Generation retired')
    admission.admit(broker, subject)


def publish(broker, token, request, subject):
    return transaction.publish(broker, token, request, subject,
                               admission=lambda candidate: admissible(broker, candidate))


def acquire(broker):
    # Snapshot, admission, and persistent reader-record creation share the same
    # lock as cooperating publication and collection, before any module load.
    with files.locked(broker):
        active = transaction.state(broker)['active']
        if active is None:
            raise ValueError('No active generation')
        subject = active['manifest']; admissible(broker, subject)
        handle = dict(readerId=uuid.uuid4().hex, libdir=root_of(subject),
                      epoch=active['epoch'], receiptId=subject['receiptId'],
                      publicationDigest=active['digest'])
        directory = broker / 'readers'; directory.mkdir(exist_ok=True)
        fd, staging = tempfile.mkstemp(prefix=handle['readerId'], suffix='.pending', dir=directory)
        with os.fdopen(fd, 'w') as stream:
            stream.write(json.dumps(handle) + '\n'); stream.flush(); os.fsync(stream.fileno())
        os.replace(staging, directory / (handle['readerId'] + '.json'))
        parent = os.open(directory, os.O_RDONLY)
        try:
            os.fsync(parent)
        finally:
            os.close(parent)
        return handle


def release(broker, handle):
    with files.locked(broker):
        if not isinstance(handle['readerId'], str) or len(handle['readerId']) != 32 or any(c not in '0123456789abcdef' for c in handle['readerId']):
            raise ValueError('Invalid reader handle')
        path = broker / 'readers' / (handle['readerId'] + '.json')
        if not path.exists() or files.read(path) != handle:
            raise ValueError('Reader handle does not match retained record')
        path.unlink()


def readers(broker, root):
    result = []
    directory = broker / 'readers'
    if directory.exists():
        for path in directory.iterdir():
            # Do not infer that malformed, abandoned, or unfamiliar records are
            # dead readers. All such records conservatively block collection.
            if path.suffix != '.json':
                raise ValueError('Unrecognized reader record')
            value = files.read(path)
            if not isinstance(value, dict) or set(value) != {'readerId', 'libdir', 'epoch', 'receiptId', 'publicationDigest'}:
                raise ValueError('Invalid retained reader record')
            if str(Path(value['libdir']).resolve()) == root:
                result.append(value)
    return result


def declare_quiescent(broker, libdir):
    # Trusted fixture coordinator assertion after completed make and known
    # owned producers; not inferred from receipts, timeouts, or dead process IDs.
    with files.locked(broker):
        value, root, _ = generation(broker, libdir)
        value['generations'][root]['writerQuiescent'] = True
        files.replace(broker / 'retention.json', value)


def collect(broker, libdir):
    with files.locked(broker):
        value, root, status = generation(broker, libdir)
        active = transaction.state(broker)['active']
        if active and root_of(active['manifest']) == root:
            raise ValueError('Active generation retained')
        if readers(broker, root):
            raise ValueError('Readers retain generation')
        if not status['writerQuiescent']:
            raise ValueError('Writer quiescence unknown')
        if status['retired']:
            raise ValueError('Generation already retired')
        owned = Path(value['ownedRoot']).resolve()
        target = Path(root)
        if target == owned or not target.is_relative_to(owned):
            raise ValueError('Collection target outside owned scratch root')
        status['retired'] = True
        files.replace(broker / 'retention.json', value)
        shutil.rmtree(target)
        return 'COLLECTED'


def worker(arguments):
    operation, *rest = arguments
    if operation == '--reader':
        control = Path(rest[0]); answer = int(rest[1])
        (control / 'ready').touch()
        files.wait_for(lambda: (control / 'release').exists(), 'retained reader module load')
        expression = '(import :closure/app) ' + f'(unless (= result {answer}) (error "Wrong answer" result)) (displayln "RETAINED-READER-OK")'
        os.execvp('gxi', ['gxi', '-e', expression])
    try:
        if operation == '--collect':
            print(collect(Path(rest[0]), rest[1]), flush=True)
        else:
            raise ValueError('Unknown study operation')
        return 0
    except (ValueError, OSError) as error:
        print(type(error).__name__ + ': ' + str(error), flush=True)
        return 70


def study(root, output, manifests, mark, runtime, environment):
    broker = root / 'retention-broker'; broker.mkdir()
    transaction.commit(broker, dict(schema=transaction.SCHEMA, epoch=0, spent=False, active=None))
    subjects = {key: admission.register(broker, m, dict(control='retention', trustedBuild=True)) for key, m in manifests.items()}
    files.replace(broker / 'retention.json', dict(ownedRoot=str(root), generations={
        root_of(s): dict(writerQuiescent=False, retired=False) for s in subjects.values()}))
    token = transaction.grant(broker); publish(broker, token, 'retention-a', subjects['a'])
    bare_pin = admission.pin(broker)
    handles = [acquire(broker), acquire(broker)]
    assert all(h['libdir'] == bare_pin['libdir'] for h in handles)
    mark('retention-acquired-before-module-load', readerCount=2, epoch=token,
         receiptId=handles[0]['receiptId'], publicationDigest=handles[0]['publicationDigest'])
    processes = []

    def start(name, command, env=None):
        print('PROBE-START', name, flush=True)
        out, err = output / (name + '.out'), output / (name + '.err')
        with out.open('w') as stdout, err.open('w') as stderr:
            proc = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        processes.append(proc)
        return proc, out, err

    def finish(name, entry, expected, marker, kind):
        proc, out, err = entry
        files.wait_for(lambda: proc.poll() is not None, name, timeout=50)
        assert proc.wait() == expected, out.read_text() + err.read_text()
        assert marker in out.read_text() + err.read_text(), out.read_text() + err.read_text()
        mark(name, commandKind=kind, exit=proc.returncode, marker=marker,
             stdoutSha256=files.sha(out), stderrSha256=files.sha(err))

    def collection(name, lib, expected, marker):
        entry = start(name, [sys.executable, str(Path(__file__).resolve()), '--collect', str(broker), str(lib)])
        before = files.sha(broker / 'state.json')
        finish(name, entry, expected, marker, 'collector')
        assert before == files.sha(broker / 'state.json')

    try:
        controls = []
        for index, handle in enumerate(handles):
            control = root / ('retained-reader-' + str(index)); control.mkdir(); controls.append(control)
            entry = start('retention-reader-' + str(index), [sys.executable, str(Path(__file__).resolve()),
                          '--reader', str(control), '42'], environment(handle['libdir']))
            handles[index]['process'] = entry  # Process metadata stays outside persisted handle.
            files.wait_for(lambda: (control / 'ready').exists(), 'reader launcher before import')
        # Remove local-only process metadata before equality-based release.
        entries = [h.pop('process') for h in handles]
        token = transaction.grant(broker); publish(broker, token, 'retention-b', subjects['b'])
        selected = acquire(broker)
        runtime('retention-selected-b-runtime', selected['libdir'], 43)
        release(broker, selected)
        collection('retention-live-readers-block-collection', bare_pin['libdir'], 70, 'Readers retain generation')
        os.killpg(entries[1][0].pid, signal.SIGKILL)
        assert entries[1][0].wait(timeout=5) == -signal.SIGKILL
        mark('retention-killed-preload-reader', commandKind='reader-launcher', exit=-signal.SIGKILL,
             stdoutSha256=files.sha(entries[1][1]), stderrSha256=files.sha(entries[1][2]), retainedReaderCount=len(readers(broker, bare_pin['libdir'])))
        (controls[0] / 'release').touch()
        finish('retention-old-reader-loads-after-switch', entries[0], 0, 'RETAINED-READER-OK', 'native-reader')
        release(broker, handles[0])
        collection('retention-dead-owner-record-blocks', bare_pin['libdir'], 70, 'Readers retain generation')
        assert len(readers(broker, bare_pin['libdir'])) == 1
        # This killed launcher acknowledged readiness before exec and never
        # spawned children. Only that owned fixture fact authorizes its release.
        release(broker, handles[1])
        mark('retention-explicit-preload-owner-release', retainedReaderCount=0,
             proof='Owned launcher killed before exec; no children created')
        collection('retention-zero-readers-not-quiescence', bare_pin['libdir'], 70, 'Writer quiescence unknown')
        declare_quiescent(broker, bare_pin['libdir'])
        declare_quiescent(broker, subjects['b']['manifest']['libdir'])
        collection('retention-active-b-blocks-collection', subjects['b']['manifest']['libdir'], 70, 'Active generation retained')
        # Malformed reader records never become implicit proof of zero readers.
        bad = broker / 'readers' / 'malformed.json'; bad.write_text('{')
        collection('retention-malformed-record-blocks', bare_pin['libdir'], 70, 'JSONDecodeError')
        bad.unlink()
        collection('retention-quiescent-unretained-a-collected', bare_pin['libdir'], 0, 'COLLECTED')
        assert not Path(bare_pin['libdir']).exists()
        token = transaction.grant(broker)
        before = files.sha(broker / 'state.json')
        try:
            publish(broker, token, 'retention-republish-a', subjects['a'])
        except ValueError as error:
            assert 'Generation retired' in str(error)
            assert files.sha(broker / 'state.json') == before
            mark('retention-retired-generation-publication-rejected', cause=str(error), tokenUnspent=True)
        else:
            raise AssertionError('Retired generation republished')
        entry = start('retention-bare-snapshot-after-collection', ['gxi', '-e', '(import :closure/app) (displayln "UNEXPECTED-LOAD")'], environment(bare_pin['libdir']))
        finish('retention-bare-snapshot-after-collection', entry, 70, 'cannot find library module', 'native-reader')
        selected = acquire(broker)
        runtime('retention-b-remains-readable', selected['libdir'], 43)
        release(broker, selected)
        mark('retention-final-state', activeReceiptId=transaction.state(broker)['active']['manifest']['receiptId'],
             retiredRoot=bare_pin['libdir'], survivingRoot=selected['libdir'], retainedReaderCount=0)
        files.replace(output / 'retention-registry.json', registry(broker))
        files.replace(output / 'retention-state.json', transaction.state(broker))
    finally:
        for proc in processes:
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
    print('GENERATION-READER-RETENTION-AND-COLLECTION-STUDIED', flush=True)


if __name__ == '__main__':
    sys.exit(worker(sys.argv[1:]))
