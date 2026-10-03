"""Run compiler-manifest admission through the single-record research broker."""
import copy
import os
from pathlib import Path
import signal
import subprocess
import sys

import publication as files
import publication_admission as admission
import publication_crash as transaction


def study(root, output, manifests, evidence, mark, runtime):
    broker = root / 'integrated-broker'; broker.mkdir()
    transaction.commit(broker, dict(schema=transaction.SCHEMA, epoch=0, spent=False, active=None))
    subjects = {key: admission.register(broker, manifest, evidence[key]) for key, manifest in manifests.items()}
    for key, subject in subjects.items():
        files.replace(output / ('registered-subject-' + key + '.json'), subject)
        files.replace(output / ('registered-receipt-' + key + '.json'), files.read(broker / 'receipts' / (subject['receiptId'] + '.json')))
    mark('integration-registered-builds', receiptIds={key: s['receiptId'] for key, s in subjects.items()},
         trustedCoordinator=True, subjectDigests={key: transaction.digest(s) for key, s in subjects.items()})
    worker = Path(admission.__file__).resolve()

    def command(name, token, request, subject, stage='none', control=None):
        candidate = root / (name + '.json'); files.replace(candidate, subject)
        return [sys.executable, str(worker), str(broker), str(token), request,
                str(candidate), stage, str(control or root)]

    def start(name, cmd):
        print('PROBE-START', name, flush=True)
        out, err = output / (name + '.out'), output / (name + '.err')
        with out.open('w') as stdout, err.open('w') as stderr:
            proc = subprocess.Popen(cmd, stdout=stdout, stderr=stderr, start_new_session=True)
        return proc, out, err

    def finish(name, entry, expected, marker):
        proc, out, err = entry
        try:
            files.wait_for(lambda: proc.poll() is not None, name)
        finally:
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
        assert proc.returncode == expected, out.read_text() + err.read_text()
        assert marker in out.read_text(), out.read_text() + err.read_text()
        mark(name, commandKind='broker', exit=proc.returncode, marker=marker,
             stdoutSha256=files.sha(out), stderrSha256=files.sha(err))

    def run(name, token, request, subject, expected=0, marker='ACK-COMMITTED'):
        finish(name, start(name, command(name, token, request, subject)), expected, marker)

    first = transaction.grant(broker)
    run('integration-publish-a', first, 'publish-a', subjects['a'])
    pinned_a = admission.pin(broker)
    assert pinned_a['receiptId'] == subjects['a']['receiptId']
    runtime('integration-initial-reader', pinned_a['libdir'], 42)
    old_token = transaction.grant(broker)
    control = root / 'old-publisher-control'; control.mkdir()
    old = start('integration-old-publisher', command('integration-old-publisher', old_token,
                'old-a', subjects['a'], 'before-admission', control))
    try:
        files.wait_for(lambda: (control / 'paused').exists(), 'old publisher prechecked')
        current = transaction.grant(broker)
        before = files.sha(broker / 'state.json')

        def reject(name, subject, cause):
            run(name, current, 'publish-b', subject, expected=70, marker=cause)
            assert files.sha(broker / 'state.json') == before
            assert not transaction.state(broker)['spent']

        unknown = dict(subjects['b'], receiptId='0' * 64)
        reject('integration-unregistered-evidence', unknown, 'Compiler evidence not registered')
        changed_graph = copy.deepcopy(subjects['b'])
        changed_graph['manifest']['graph']['modules'].remove('closure/phase-dep')
        reject('integration-candidate-graph-rewrite', changed_graph, 'Candidate differs from registered build')
        missing = copy.deepcopy(subjects['b'])
        missing['manifest']['files'].pop('closure/phase-dep.o1')
        reject('integration-candidate-inventory-rewrite', missing, 'Candidate differs from registered build')
        receipt_path = broker / 'receipts' / (subjects['b']['receiptId'] + '.json')
        saved_receipt = receipt_path.read_bytes()
        try:
            changed = files.read(receipt_path); changed['evidence']['tampered'] = True
            files.replace(receipt_path, changed)
            reject('integration-registered-receipt-drift', subjects['b'], 'Registered receipt digest mismatch')
        finally:
            receipt_path.write_bytes(saved_receipt)
        object_path = Path(manifests['b']['libdir']) / 'closure/phase-dep.o1'
        saved_object = object_path.read_bytes()
        try:
            object_path.write_bytes(saved_object + b'changed-after-registration')
            reject('integration-object-drift', subjects['b'], 'Artifact digest mismatch')
            rehashed = copy.deepcopy(subjects['b'])
            rehashed['manifest']['files']['closure/phase-dep.o1'] = files.sha(object_path)
            reject('integration-candidate-rehash', rehashed, 'Candidate differs from registered build')
        finally:
            object_path.write_bytes(saved_object)
        mark('integration-rejections-preserve-active-a', stateSha256=before,
             activeReceiptId=transaction.state(broker)['active']['manifest']['receiptId'], tokenUnspent=True)
        run('integration-publish-b', current, 'publish-b', subjects['b'])
        pinned_b = admission.pin(broker)
        assert pinned_b['receiptId'] == subjects['b']['receiptId']
        runtime('integration-selected-b-reader', pinned_b['libdir'], 43)
        runtime('integration-pinned-a-reader', pinned_a['libdir'], 42)
        before = files.sha(broker / 'state.json')
        (control / 'release').touch()
        finish('integration-old-publisher-rejected', old, 70, 'Publication authority superseded')
        assert files.sha(broker / 'state.json') == before
        mark('integration-stale-publisher-preserves-b', stateSha256=before,
             activeReceiptId=pinned_b['receiptId'], publicationDigest=pinned_b['publicationDigest'])
    finally:
        if old[0].poll() is None:
            os.killpg(old[0].pid, signal.SIGKILL)
        old[0].wait()

    token = transaction.grant(broker)
    control = root / 'commit-crash-control'; control.mkdir()
    interrupted = start('integration-commit-before-ack', command('integration-commit-before-ack', token,
                        'publish-b-crash', subjects['b'], 'directory-synced', control))
    try:
        files.wait_for(lambda: (control / 'paused').exists(), 'committed state before acknowledgement')
        os.killpg(interrupted[0].pid, signal.SIGKILL)
        assert interrupted[0].wait(timeout=5) == -signal.SIGKILL
        mark('integration-killed-after-commit', commandKind='broker', exit=-signal.SIGKILL,
             checkpoint=(control / 'paused').read_text(), stdoutSha256=files.sha(interrupted[1]), stderrSha256=files.sha(interrupted[2]))
    finally:
        if interrupted[0].poll() is None:
            os.killpg(interrupted[0].pid, signal.SIGKILL)
        interrupted[0].wait()
    committed = transaction.state(broker)
    assert committed['spent'] and committed['active']['manifest'] == subjects['b']
    before = files.sha(broker / 'state.json')
    run('integration-committed-request-replay', token, 'publish-b-crash', subjects['b'], marker='ACK-REPLAY')
    run('integration-replay-different-evidence', token, 'publish-b-crash', subjects['a'],
        expected=70, marker='Consumed token request mismatch')
    run('integration-replay-different-request', token, 'other-request', subjects['b'],
        expected=70, marker='Consumed token request mismatch')
    assert files.sha(broker / 'state.json') == before

    # An acknowledgement resolves the historical committed request; a reader
    # must separately admit the stored generation's current bytes before use.
    object_path = Path(manifests['b']['libdir']) / 'closure/phase-dep.o1'
    saved_object = object_path.read_bytes()
    try:
        object_path.write_bytes(saved_object + b'post-commit-drift')
        run('integration-replay-with-storage-drift', token, 'publish-b-crash', subjects['b'], marker='ACK-REPLAY')
        try:
            admission.pin(broker)
        except ValueError as error:
            assert 'Artifact digest mismatch' in str(error)
            mark('integration-reader-rejects-storage-drift', cause=str(error),
                 historicalAcknowledgementOnly=True, stateSha256=files.sha(broker / 'state.json'))
        else:
            raise AssertionError('Mutated storage admitted to reader')
    finally:
        object_path.write_bytes(saved_object)
    assert files.sha(broker / 'state.json') == before
    pinned = admission.pin(broker)
    runtime('integration-reader-after-recovery', pinned['libdir'], 43)
    mark('integration-committed-identity-retained', epoch=pinned['epoch'], receiptId=pinned['receiptId'],
         publicationDigest=pinned['publicationDigest'], stateSha256=before)
    files.replace(output / 'integrated-state.json', transaction.state(broker))
    print('COMPILER-CLOSURE-TRANSACTION-INTEGRATED', flush=True)
