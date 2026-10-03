#!/usr/bin/env python3
"""Bind a compiler-derived candidate to broker-owned research build evidence.

Registration is a trusted fixture coordinator action. Content hashes are identity
checks, not signatures, client authentication, or immutable-storage enforcement.
"""
import json
import re
import sys
from pathlib import Path

import closure
import publication as files
import publication_crash as transaction


def register(broker, manifest, evidence):
    closure.admit(manifest, manifest['graph'])
    receipt = dict(schema='asp.compiler-closure-admission-study.v1',
                   graph=manifest['graph'], manifestDigest=transaction.digest(manifest),
                   evidence=evidence)
    identity = transaction.digest(receipt)
    with files.locked(broker):
        directory = broker / 'receipts'; directory.mkdir(exist_ok=True)
        path = directory / (identity + '.json')
        if path.exists():
            if files.read(path) != receipt:
                raise ValueError('Registered receipt changed')
        else:
            files.replace(path, receipt)
    return dict(receiptId=identity, manifest=manifest)


def admit(broker, subject):
    if not isinstance(subject, dict) or set(subject) != {'receiptId', 'manifest'}:
        raise ValueError('Invalid publication subject')
    identity = subject['receiptId']
    if not isinstance(identity, str) or not re.fullmatch('[0-9a-f]{64}', identity):
        raise ValueError('Invalid receipt identity')
    path = broker / 'receipts' / (identity + '.json')
    if not path.is_file():
        raise ValueError('Compiler evidence not registered')
    receipt = files.read(path)
    if transaction.digest(receipt) != identity:
        raise ValueError('Registered receipt digest mismatch')
    if receipt['manifestDigest'] != transaction.digest(subject['manifest']):
        raise ValueError('Candidate differs from registered build')
    closure.admit(subject['manifest'], receipt['graph'])


def publish(broker, token, request, subject, checkpoint=lambda stage: None):
    return transaction.publish(broker, token, request, subject, checkpoint,
                               admission=lambda candidate: admit(broker, candidate))


def pin(broker):
    # One atomic state read pins both selected subject and publication identity.
    # Revalidation detects controlled byte drift before launching a fresh reader;
    # it is not protection against mutation after validation.
    active = transaction.state(broker)['active']
    if active is None:
        raise ValueError('No active admitted generation')
    admit(broker, active['manifest'])
    return dict(epoch=active['epoch'], request=active['request'],
                publicationDigest=active['digest'], receiptId=active['manifest']['receiptId'],
                libdir=active['manifest']['manifest']['libdir'])


def worker(arguments):
    broker_name, token_text, request, subject_name, stage, control_name = arguments
    broker, control = Path(broker_name), Path(control_name)
    subject = files.read(Path(subject_name))

    def checkpoint(current):
        if current == stage:
            (control / 'paused').write_text(current)
            files.wait_for(lambda: (control / 'release').exists(), current)

    try:
        if stage == 'before-admission':
            admit(broker, subject)
            checkpoint(stage)
        result = publish(broker, int(token_text), request, subject, checkpoint)
        print(result, flush=True)
        return 0
    except (ValueError, OSError) as error:
        print(type(error).__name__ + ': ' + str(error), flush=True)
        return 70


if __name__ == '__main__':
    sys.exit(worker(sys.argv[1:]))
