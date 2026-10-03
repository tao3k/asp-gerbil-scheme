#!/usr/bin/env python3
"""Local process-death controls for reader records and resumable retirement."""
import copy
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys

import publication as files
import publication_admission as admission
import publication_crash as transaction
import publication_retention as retention


def worker(arguments):
    operation, broker_name, stage, control_name, payload = arguments
    broker, control = Path(broker_name), Path(control_name)

    def checkpoint(current, handle=None):
        if current == stage:
            if handle is not None:
                files.replace(control / 'handle.json', handle)
            (control / 'paused').write_text(current)
            files.wait_for(lambda: (control / 'release').exists(), current)

    try:
        if operation == 'acquire':
            handle = retention.acquire(broker, checkpoint)
            print('ACQUIRED', json.dumps(handle), flush=True)
        elif operation == 'release':
            print(retention.release(broker, files.read(Path(payload)), checkpoint), flush=True)
        elif operation == 'collect':
            print(retention.collect(broker, payload, checkpoint), flush=True)
        else:
            raise ValueError('Unknown operation')
        return 0
    except (ValueError, OSError) as error:
        print(type(error).__name__ + ': ' + str(error), flush=True)
        return 70


def study(root, output, manifests, mark, runtime):
    broker = root / 'retention-crash-broker'; broker.mkdir()
    transaction.commit(broker, dict(schema=transaction.SCHEMA, epoch=0, spent=False, active=None))
    subjects = {key: admission.register(broker, m, dict(control='retention-crash', trustedBuild=True)) for key, m in manifests.items()}
    files.replace(broker / 'retention.json', dict(ownedRoot=str(root), generations={
        retention.root_of(s): dict(writerQuiescent=False, retired=False) for s in subjects.values()}))
    target = Path(manifests['a']['libdir'])
    processes = []

    def select(key):
        token = transaction.grant(broker)
        retention.publish(broker, token, 'select-' + key + '-' + str(token), subjects[key])

    def start(name, operation, stage='none', payload='none', control=None):
        print('PROBE-START', name, flush=True)
        out, err = output / (name + '.out'), output / (name + '.err')
        command = [sys.executable, str(Path(__file__).resolve()), operation, str(broker),
                   stage, str(control or root), str(payload)]
        with out.open('w') as stdout, err.open('w') as stderr:
            proc = subprocess.Popen(command, stdout=stdout, stderr=stderr, start_new_session=True)
        processes.append(proc)
        return proc, out, err

    def run(name, operation, payload, expected=0, marker=None):
        proc, out, err = start(name, operation, payload=payload)
        files.wait_for(lambda: proc.poll() is not None, name)
        assert proc.wait() == expected, out.read_text() + err.read_text()
        assert marker in out.read_text(), out.read_text() + err.read_text()
        mark(name, commandKind='retention-operation', exit=proc.returncode, marker=marker,
             stdoutSha256=files.sha(out), stderrSha256=files.sha(err))

    def kill(name, operation, stage, payload='none'):
        control = root / name; control.mkdir()
        entry = start(name, operation, stage, payload, control)
        files.wait_for(lambda: (control / 'paused').exists(), name)
        os.killpg(entry[0].pid, signal.SIGKILL)
        assert entry[0].wait(timeout=5) == -signal.SIGKILL
        mark(name, commandKind='retention-operation', exit=-signal.SIGKILL,
             stage=(control / 'paused').read_text(), stdoutSha256=files.sha(entry[1]), stderrSha256=files.sha(entry[2]))
        return control

    try:
        for stage in ['before-reader-stage', 'reader-stage-synced', 'reader-record-installed', 'reader-directory-synced']:
            select('a')
            control = kill('retention-crash-acquire-' + stage, 'acquire', stage)
            handle = files.read(control / 'handle.json')
            select('b')
            paths = list((broker / 'readers').iterdir())
            if stage == 'before-reader-stage':
                assert not paths
                mark('retention-crash-no-reader-started', stage=stage, readerRecordCount=0,
                     proof='Killed acquisition worker has no module launcher or children')
            else:
                assert len(paths) == 1
                expected = 'Unrecognized reader record' if stage == 'reader-stage-synced' else 'Readers retain generation'
                run('retention-crash-acquire-blocks-' + stage, 'collect', target, 70, expected)
                # Scoped trusted recovery: this operation never returned a pin
                # or launched a reader. Verify exact original record bytes.
                if stage == 'reader-stage-synced':
                    with files.locked(broker):
                        assert files.read(paths[0]) == handle
                        paths[0].unlink()
                else:
                    retention.release(broker, handle)
                mark('retention-crash-owned-preload-record-recovered-' + stage,
                     proof='Owned killed acquisition never returned or launched a reader', readerRecordCount=0)
            assert not list((broker / 'readers').iterdir()) and target.exists()

        for stage in ['before-release-intent', 'release-intent-recorded', 'reader-record-unlinked', 'release-directory-synced']:
            select('a'); handle = retention.acquire(broker)
            payload = root / (stage + '-handle.json'); files.replace(payload, handle)
            select('b')
            kill('retention-crash-release-' + stage, 'release', stage, payload)
            still_retained = (broker / 'readers' / (handle['readerId'] + '.json')).exists()
            assert still_retained == (stage in ['before-release-intent', 'release-intent-recorded'])
            if still_retained:
                run('retention-crash-release-blocks-' + stage, 'collect', target, 70, 'Readers retain generation')
            else:
                assert files.read(broker / 'released' / (handle['readerId'] + '.json')) == handle
                mark('retention-crash-unlinked-with-release-intent-' + stage, exactReleaseIntent=True)
            wrong = copy.deepcopy(handle); wrong['epoch'] += 1
            wrong_path = root / (stage + '-wrong-handle.json'); files.replace(wrong_path, wrong)
            run('retention-crash-wrong-release-' + stage, 'release', wrong_path, 70,
                'Release intent does not match handle' if stage != 'before-release-intent' else 'Reader handle does not match retained record')
            run('retention-crash-release-retry-' + stage, 'release', payload, marker='RELEASED' if still_retained else 'ACK-RELEASE-REPLAY')
            run('retention-crash-release-replay-' + stage, 'release', payload, marker='ACK-RELEASE-REPLAY')
            assert not list((broker / 'readers').iterdir()) and target.exists()

        select('b')
        retention.declare_quiescent(broker, target)
        backup = root / 'collection-fixture-backup'; shutil.copytree(target, backup)
        for stage in ['retirement-recorded', 'collection-partial-delete', 'collection-root-removed', 'collection-completion-recorded']:
            # Sequential isolated scratch cases restore original bytes only
            # after every owned actor ended and all reader records were released.
            assert not list((broker / 'readers').iterdir())
            if not target.exists():
                shutil.copytree(backup, target)
            value = retention.registry(broker)
            value['generations'][str(target)].update(retired=False, collected=False)
            files.replace(broker / 'retention.json', value)
            before = files.sha(broker / 'state.json')
            kill('retention-crash-collect-' + stage, 'collect', stage, target)
            status = retention.registry(broker)['generations'][str(target)]
            assert status['retired']
            assert status.get('collected', False) == (stage == 'collection-completion-recorded')
            assert target.exists() == (stage in ['retirement-recorded', 'collection-partial-delete'])
            token = transaction.grant(broker)
            try:
                retention.publish(broker, token, 'retired-republish', subjects['a'])
            except ValueError as error:
                assert 'Generation retired' in str(error)
                mark('retention-crash-retired-publication-refused-' + stage, cause=str(error), tokenUnspent=True)
            else:
                raise AssertionError('Retired generation published')
            before = files.sha(broker / 'state.json')
            value = retention.registry(broker); value['generations'][str(target)]['writerQuiescent'] = False
            files.replace(broker / 'retention.json', value)
            run('retention-crash-resume-rechecks-quiescence-' + stage, 'collect', target, 70, 'Writer quiescence unknown')
            retention.declare_quiescent(broker, target)
            run('retention-crash-collection-resume-' + stage, 'collect', target,
                marker='ACK-COLLECTION-REPLAY' if stage == 'collection-completion-recorded' else 'COLLECTION-RESUMED')
            assert not target.exists() and retention.registry(broker)['generations'][str(target)]['collected']
            run('retention-crash-collection-replay-' + stage, 'collect', target, marker='ACK-COLLECTION-REPLAY')
            assert before == files.sha(broker / 'state.json')
            selected = admission.pin(broker)
            runtime('retention-crash-surviving-b-' + stage, selected['libdir'], 43)
        target.mkdir()
        run('retention-crash-reappeared-root-refused', 'collect', target, 70, 'Collected generation root reappeared')
        assert target.exists(); target.rmdir()
        files.replace(output / 'retention-crash-registry.json', retention.registry(broker))
        files.replace(output / 'retention-crash-state.json', transaction.state(broker))
        mark('retention-crash-final', readerRecordCount=0, retiredAndCollected=True,
             activeReceiptId=transaction.state(broker)['active']['manifest']['receiptId'])
    finally:
        for proc in processes:
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
    print('RETENTION-ACQUISITION-RELEASE-AND-COLLECTION-CRASHES-STUDIED', flush=True)


if __name__ == '__main__':
    sys.exit(worker(sys.argv[1:]))
