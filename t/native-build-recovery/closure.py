#!/usr/bin/env python3
"""Qualify native expander import facts as a bounded generation manifest input."""
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile

import publication as helper

INTERFACE_SUFFIXES = ['.ssi', '.native-complete', '.native-source', '.native-interface']


def derive(rows, entry, sources, lib, external_root):
    nodes = {row['id']: row for row in rows}
    if len(nodes) != len(rows) or set(nodes) != set(sources):
        raise ValueError('Build inventory and expander identities disagree')
    reached, edges, external = set(), [], []
    pending = [entry]
    while pending:
        owner = pending.pop()
        if owner in reached:
            continue
        reached.add(owner)
        row = nodes[owner]
        if Path(row['path']).resolve() != sources[owner].resolve():
            raise ValueError('Source owner path mismatch')
        for fact in row['imports']:
            target = fact['to']
            if target in nodes:
                expected = {sources[target].resolve(), (lib / (target + '.ssi')).resolve()}
                if not fact['path'] or Path(fact['path']).resolve() not in expected:
                    raise ValueError('Local dependency resolved outside generation: ' + target)
                pending.append(target); edges.append(fact)
            else:
                if fact['path']:
                    path = Path(fact['path']).resolve()
                    if not path.is_relative_to(external_root.resolve()):
                        raise ValueError('Unapproved external dependency path: ' + str(path))
                    external.append(dict(fact, interfaceSha256=helper.sha(path)))
                else:
                    external.append(dict(fact, interfaceSha256=None))
    return dict(entry=entry, modules=sorted(reached), edges=edges, externalFrontier=external)


def seal(graph, sources, lib):
    files = {}
    for module in graph['modules']:
        if sources[module].read_bytes() != (lib / (module + '.native-source')).read_bytes():
            raise ValueError('Source changed since completed build: ' + module)
        for suffix in INTERFACE_SUFFIXES:
            relative = module + suffix
            files[relative] = helper.sha(lib / relative)
        for relative in graph['nativeObjects'][module]:
            files[relative] = helper.sha(lib / relative)
    return dict(graph=graph, libdir=str(lib), files=files)


def admit(manifest, graph):
    if manifest['graph'] != graph:
        raise ValueError('Manifest graph differs from compiler evidence')
    expected = {module + suffix for module in graph['modules'] for suffix in INTERFACE_SUFFIXES}
    expected.update(relative for paths in graph['nativeObjects'].values() for relative in paths)
    if set(manifest['files']) != expected:
        raise ValueError('Incomplete compiler-derived inventory')
    for relative, digest in manifest['files'].items():
        path = Path(manifest['libdir']) / relative
        if not path.is_file() or helper.sha(path) != digest:
            raise ValueError('Artifact digest mismatch: ' + relative)
    for fact in graph['externalFrontier']:
        if fact['path'] and helper.sha(Path(fact['path'])) != fact['interfaceSha256']:
            raise ValueError('External interface digest mismatch')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--make-source', type=Path, required=True)
    parser.add_argument('--patch', type=Path, required=True)
    parser.add_argument('--native-gsc', type=Path, required=True)
    parser.add_argument('--external-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--publication-study', action='store_true')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    extractor = Path(__file__).with_suffix('.ss').resolve()
    assert helper.sha(args.make_source) == helper.read(args.patch.parent / 'patch-bases.json')['installed']['sourceSha256']
    observations = []

    def mark(name, **fields):
        row = dict(name=name, **fields); observations.append(row)
        helper.replace(args.output / 'observations.json', observations)
        print('PROBE-END', json.dumps(row), flush=True)

    with tempfile.TemporaryDirectory(prefix='gerbil-compiler-closure-') as temporary:
        root = Path(temporary).resolve()
        make = root / 'native-make.ss'; make.write_bytes(args.make_source.read_bytes())
        subprocess.run(['patch', '-f', str(make)], input=args.patch.read_text(), text=True,
                       capture_output=True, check=True)
        patched_hash = helper.sha(make)
        # Expose the retained compiler's structural SSI output walker only in
        # this scratch module; do not change or duplicate its implementation.
        make.write_text(make.read_text() + '''
(export closure-native-outputs)
(def (closure-native-outputs spec src lib)
  (native-outputs spec (make-settings srcdir: src libdir: lib)))
''')

        def env(loadpath):
            value = dict(os.environ, GERBIL_PATH=str(root / 'runtime'), GERBIL_LOADPATH=str(loadpath),
                         GERBIL_GSC=str(args.native_gsc.resolve()), GERBIL_BUILD_CORES='2')
            for key in ['SDKROOT', 'DEVELOPER_DIR']:
                value.pop(key, None)
            return value

        def run(name, expression, loadpath, marker=None, answer=None):
            print('PROBE-START', name, flush=True)
            out, err = args.output / (name + '.out'), args.output / (name + '.err')
            with out.open('w') as stdout, err.open('w') as stderr:
                proc = subprocess.Popen(['gxi', '-e', expression], env=env(loadpath),
                                        stdout=stdout, stderr=stderr, start_new_session=True)
            try:
                helper.wait_for(lambda: proc.poll() is not None, name, timeout=50)
            finally:
                if proc.poll() is None:
                    os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            assert proc.returncode == 0, out.read_text() + err.read_text()
            if marker:
                assert marker in out.read_text(), err.read_text()
            mark(name, exit=proc.returncode, marker=marker, expectedAnswer=answer,
                 stdoutSha256=helper.sha(out), stderrSha256=helper.sha(err))
            return out.read_text()

        def runtime(name, lib, answer):
            run(name, '(import :closure/app) ' + f'(unless (= result {answer}) (error "Wrong answer" result)) (displayln "RUNTIME-OK")',
                lib, marker='RUNTIME-OK', answer=answer)

        def extract(name, sources, lib):
            expression = '(import ' + json.dumps(str(extractor)) + ') (main '
            expression += ' '.join(json.dumps(str(p)) for p in sources.values()) + ')'
            rows = json.loads(run(name, expression, lib))
            helper.replace(args.output / (name + '.facts.json'), rows)
            return rows

        libs, inventories, graphs, manifests = {}, {}, {}, {}
        for key, seed in [('a', 32), ('b', 33)]:
            src, lib = root / ('src-' + key), root / ('lib-' + key)
            src.mkdir(); lib.mkdir(); libs[key] = lib
            (src / 'gerbil.pkg').write_text('(package: closure)\n')
            bodies = {
                'leaf': f'(export seed)\n(def seed {seed})\n',
                'middle': '(import (rename-in (only-in :closure/leaf seed) (seed renamed-seed)))\n(export answer)\n(def answer renamed-seed)\n',
                'bridge': '(import :closure/middle)\n(export (import: :closure/middle))\n',
                'phase-dep': '(export phase-value)\n(def phase-value 2)\n',
                'phase': '(import :closure/phase-dep)\n(export value)\n(def value (+ 8 phase-value))\n',
                'app': '(import (only-in :closure/bridge answer) (for-syntax :closure/phase) (only-in :std/list/list flatten))\n(export result)\n(begin-syntax (def compile-bias value))\n(defsyntax (bias stx) (datum->syntax #\'bias compile-bias))\n(def result (apply + (flatten [(bias) [answer]])))\n',
                'unused': '(export unused)\n(def unused 999)\n',
            }
            inventory = {}
            for module, body in bodies.items():
                path = src / (module + '.ss'); path.write_text(body)
                inventory['closure/' + module] = path
            inventories[key] = inventory
            expression = '(import ' + json.dumps(str(make)) + ') (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () '
            expression += '(make [' + ' '.join(json.dumps(m) for m in bodies) + '] srcdir: ' + json.dumps(str(src)) + ' libdir: ' + json.dumps(str(lib)) + ' parallelize: 2 force: #t) (displayln "BUILD-OK")))'
            run('build-' + key, expression, lib, marker='BUILD-OK')
            runtime('runtime-' + key, lib, seed + 10)
            rows = extract('source-imports-' + key, inventory, lib)
            graph = derive(rows, 'closure/app', inventory, lib, args.external_root)
            assert set(graph['modules']) == set(inventory) - {'closure/unused'}
            assert any(f['to'] == 'closure/phase' and f['phi'] == 1 for f in graph['edges'])
            assert any(f['to'] == 'closure/leaf' and f['kind'] == 'binding' for f in graph['edges'])
            assert graph['externalFrontier']
            expression = '(import ' + json.dumps(str(make)) + ' :std/encoding/json) '
            expression += '(write-json (current-output-port) (map (lambda (name) (closure-native-outputs name '
            expression += json.dumps(str(src)) + ' ' + json.dumps(str(lib)) + ')) ['
            expression += ' '.join(json.dumps(m) for m in bodies) + ']))'
            outputs = json.loads(run('native-output-facts-' + key, expression, lib))
            owned = {}
            for module, paths in zip(inventory, outputs, strict=True):
                owned[module] = [str(Path(path).resolve().relative_to(lib.resolve())) for path in paths]
                assert owned[module] and all(path.endswith('.o1') for path in owned[module])
            graph['nativeObjects'] = {module: owned[module] for module in graph['modules']}
            assert len(graph['nativeObjects']['closure/bridge']) == 1
            graphs[key] = graph; manifests[key] = seal(graph, inventory, lib)
            admit(manifests[key], graph)
            mark('derived-closure-' + key, modules=graph['modules'], artifactCount=len(manifests[key]['files']),
                 phaseOneDependency=True, renamedBinding=True, externalFactCount=len(graph['externalFrontier']))

        partial = root / 'partial'; shutil.copytree(libs['b'], partial)
        for path in (partial / 'closure').glob('leaf*'):
            path.unlink()
        fallback = str(partial) + os.pathsep + str(libs['a'])
        runtime('partial-runtime-with-fallback', fallback, 42)
        rows = extract('partial-imports', inventories['b'], fallback)
        try:
            derive(rows, 'closure/app', inventories['b'], partial, args.external_root)
        except ValueError as error:
            assert 'Local dependency resolved outside generation' in str(error), error
            mark('fallback-local-owner-rejected', cause=str(error))
        else:
            raise AssertionError('Fallback owner admitted')

        incomplete = dict(manifests['b'], files={k: v for k, v in manifests['b']['files'].items() if not k.startswith('closure/phase-dep.') and not k.startswith('closure/phase-dep~')})
        try:
            admit(incomplete, graphs['b'])
        except ValueError as error:
            assert 'Incomplete compiler-derived inventory' in str(error)
            mark('transitive-phase-inventory-rejected', cause=str(error))
        else:
            raise AssertionError('Transitive dependency omitted')
        if args.publication_study:
            import publication_integration
            evidence = {key: dict(importFactsSha256=helper.sha(args.output / ('source-imports-' + key + '.facts.json')),
                        outputFactsSha256=helper.sha(args.output / ('native-output-facts-' + key + '.out')),
                        extractorSha256=helper.sha(extractor), patchedSourceSha256=patched_hash,
                        nativeGscSha256=helper.sha(args.native_gsc)) for key in manifests}
            publication_integration.study(root, args.output, manifests, evidence, mark, runtime)
        changed = inventories['b']['closure/app']; changed.write_text(changed.read_text() + '\n;; Changed after build.\n')
        try:
            seal(graphs['b'], inventories['b'], libs['b'])
        except ValueError as error:
            assert 'Source changed since completed build' in str(error)
            mark('changed-source-evidence-rejected', cause=str(error))
        else:
            raise AssertionError('Changed source sealed')
        helper.replace(args.output / 'study.json', dict(schema='asp.native-compiler-closure-study.v1',
                       patchedSourceSha256=patched_hash, instrumentedSourceSha256=helper.sha(make), patchSha256=helper.sha(args.patch),
                       nativeGscSha256=helper.sha(args.native_gsc), runnerSha256=helper.sha(Path(__file__)),
                       extractorSha256=helper.sha(extractor), sharedHarnessSha256=helper.sha(Path(helper.__file__)),
                       externalRoot=str(args.external_root.resolve()), publicationStudy=args.publication_study, observations=observations,
                       manifests=manifests, retainedCompilerPatchChanged=False))
    print('COMPILER-OWNED-APPLICATION-CLOSURE-STUDIED', flush=True)


if __name__ == '__main__':
    main()
