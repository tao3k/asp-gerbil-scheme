#!/usr/bin/env python3
"""Study root aliases, descendant aliases, escaped backends, and private generations.

Every reclamation in this script affects its own temporary fixture. None is a
production recovery action or an amendment to the retained compiler patches.
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
base = args.make_source.read_bytes()
bases = json.loads((args.patch.parent / 'patch-bases.json').read_text())
assert hashlib.sha256(base).hexdigest() == bases[args.patch.name.split('-')[0]]['sourceSha256']
args.output.mkdir(parents=True, exist_ok=True)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
observations = []

def mark(case, name, **fields):
    row = dict(case=case, name=name, **fields); observations.append(row)
    (args.output / 'receipts.json').write_text(json.dumps(observations, indent=2)+'\n')
    print('PROBE-END', json.dumps(row), flush=True)

with tempfile.TemporaryDirectory(prefix='gerbil-namespace-study-') as temporary:
    root = Path(temporary).resolve()
    source = root / 'native-make.ss'; source.write_bytes(base)
    subprocess.run(['patch', '-f', str(source)], input=args.patch.read_text(), text=True, capture_output=True, check=True)
    patched_hash = sha(source)
    original = source.read_text()
    assert original.count('(def (make buildspec . rest)') == 1
    # Ordinary error release relies on the already-qualified frontend/native
    # drain. Forced death cannot run this handler and leaves the directory claim.
    source.write_text(original.replace('(def (make buildspec . rest)', '(def (make/without-study-claim buildspec . rest)') + '''
(def (make buildspec . rest)
  (def settings (apply make-settings rest))
  (def directory (settings-libdir settings))
  (create-directory* directory)
  (def claim (path-expand ".experimental-native-write-lease" directory))
  (with-catch
    (lambda (e)
      (if (file-exists? claim) (error "Output namespace occupied" claim) (raise e)))
    (lambda () (create-directory claim)))
  (def result (with-catch
    (lambda (e) (delete-directory claim) (raise e))
    (lambda () (apply make/without-study-claim buildspec rest))))
  (delete-directory claim)
  result)
''')

    class Fixture:
        def __init__(self, name, mode, detached=False):
            self.name = name; self.dir = root / name; self.dir.mkdir()
            self.log = args.output / name; self.log.mkdir(exist_ok=True)
            self.processes = []; self.records = []; self.detached = detached
            if mode == 'root-alias':
                shared = self.dir / 'shared'; shared.mkdir()
                alias = self.dir / 'alias'; alias.symlink_to(shared, target_is_directory=True)
                self.libs = dict(a=shared, b=alias)
            elif mode == 'descendant-alias':
                shared = self.dir / 'shared-module'; shared.mkdir()
                self.libs = dict(a=self.dir/'lib-a', b=self.dir/'lib-b')
                for lib in self.libs.values():
                    lib.mkdir(); (lib/'writers').symlink_to(shared, target_is_directory=True)
                assert self.libs['a'].resolve() != self.libs['b'].resolve()
                assert (self.libs['a']/'writers').resolve() == (self.libs['b']/'writers').resolve()
            elif mode == 'shared':
                shared = self.dir/'shared'; shared.mkdir(); self.libs=dict(a=shared,b=shared)
            else:
                self.libs = dict(a=self.dir/'generation-a', b=self.dir/'generation-b')
                for lib in self.libs.values(): lib.mkdir()
            for writer, answer in [('a',42),('b',43)]:
                src = self.dir/writer; src.mkdir()
                (src/'gerbil.pkg').write_text('(package: writers)\n')
                (src/'middle.ss').write_text(f'(export answer)\n(def answer {answer})\n')
                control = self.dir/(writer+'-control'); control.mkdir()
                backend = control/'gsc'
                backend.write_text('#!'+sys.executable+'\n'+'''import os,sys,json,time,shutil
from pathlib import Path
control=Path(__file__).parent
arguments=sys.argv[1:]
original=Path(arguments[-1]); assert original.suffix=='.scm' and '-o' not in arguments
wrapper=os.getpid(); wrapper_group=os.getpgrp()
if '''+repr(detached and writer=='a')+''':
    child=os.fork()
    if child:
        _, status=os.waitpid(child,0)
        code=os.waitstatus_to_exitcode(status)
        sys.exit(code if code>=0 else 128-code)
    os.setsid()
frozen=control/original.name
shutil.copyfile(original,frozen)
record=control/(original.name+'.ready'); pending=record.with_suffix('.pending')
pending.write_text(json.dumps({'wrapperPid':wrapper,'wrapperGroup':wrapper_group,'workerPid':os.getpid(),'workerGroup':os.getpgrp(),'input':str(original),'target':str(original.with_suffix('.o1'))}))
pending.replace(record)
while not (control/'release').exists():
    if (control/'ping').exists() and not (control/(original.name+'.alive')).exists():
        ack=control/(original.name+'.alive'); temporary=ack.with_suffix('.pending-alive')
        temporary.write_text(str(os.getpid())); temporary.replace(ack)
    time.sleep(.01)
os.execv('''+repr(str(args.native_gsc.resolve()))+', ['+repr(str(args.native_gsc.resolve()))+''', *arguments[:-1], '-o', str(original.with_suffix('.o1')), str(frozen)])
'''); backend.chmod(0o700)

        def env(self, writer, pinned=None):
            env=dict(os.environ,GERBIL_PATH=str(self.dir/writer),GERBIL_LOADPATH=str(pinned or self.libs[writer]),
                     GERBIL_GSC=str(self.dir/(writer+'-control')/'gsc'),GERBIL_BUILD_CORES='12')
            for key in ['SDKROOT','DEVELOPER_DIR']: env.pop(key,None)
            return env

        def start(self, name, writer, force=True, runtime=None, pinned=None):
            print('PROBE-START',self.name,name,flush=True)
            if runtime is None:
                imports='(import '+json.dumps(str(source))+')'
                body='(make ["middle"] srcdir: '+json.dumps(str(self.dir/writer))+' libdir: '+json.dumps(str(self.libs[writer]))+' parallelize: 12 force: '+('#t' if force else '#f')+') (displayln "BUILD-OK")'
            else:
                imports='(import :writers/middle)'
                body='(unless (= answer '+str(runtime)+') (error "Wrong runtime value" answer)) (displayln "RUNTIME-OK")'
            expression=imports+' (with-catch (lambda (e) (display-exception e (current-error-port)) (exit 70)) (lambda () '+body+'))'
            out=self.log/(name+'.out'); err=self.log/(name+'.err')
            with out.open('w') as stdout,err.open('w') as stderr:
                proc=subprocess.Popen(['gxi','-e',expression],env=self.env(writer,pinned),stdout=stdout,stderr=stderr,start_new_session=True)
            entry=dict(name=name,writer=writer,proc=proc,out=out,err=err,runtime=runtime)
            self.processes.append(entry); return entry

        def until(self, predicate, description):
            deadline=time.monotonic()+args.timeout
            while not predicate():
                if time.monotonic()>deadline: raise TimeoutError(description)
                time.sleep(.01)

        def capture(self, entry):
            control=self.dir/(entry['writer']+'-control')
            self.until(lambda:len(list(control.glob('*.ready')))==2,'two captured jobs')
            records=[json.loads(p.read_text()) for p in sorted(control.glob('*.ready'))]
            assert all(r['wrapperGroup']==entry['proc'].pid for r in records)
            for r in records:
                if self.detached and entry['writer']=='a':
                    assert r['workerGroup']==r['workerPid'] and r['workerGroup']!=entry['proc'].pid
                else: assert r['workerGroup']==entry['proc'].pid
                frozen=control/Path(r['input']).name
                r['inputSha256']=sha(frozen)
            self.records.extend(records)
            (self.log/(entry['name']+'.captures.json')).write_text(json.dumps(records,indent=2)+'\n')
            mark(self.name,entry['name']+'-capture',jobs=2,detached=self.detached and entry['writer']=='a')
            return records

        def release(self, writer): (self.dir/(writer+'-control')/'release').touch()
        def inventory(self, writer):
            directory=self.libs[writer]/'writers'
            return {p.name:sha(p) for p in directory.iterdir() if p.is_file()}
        def finish(self, entry, status=0, cause=None, compile_count=None):
            observed=entry['proc'].wait(timeout=args.timeout)
            stdout,stderr=entry['out'].read_text(),entry['err'].read_text()
            assert observed==status,stdout+stderr
            if cause: assert cause in stderr and 'BUILD-OK' not in stdout
            else: assert ('RUNTIME-OK' if entry['runtime'] is not None else 'BUILD-OK') in stdout,stderr
            count=stdout.count('... compile middle')
            if compile_count is not None: assert count==compile_count
            mark(self.name,entry['name'],exit=observed,compileCount=count,cause=cause,runtime=entry['runtime'])

        def kill_frontend_and_direct_group(self, entry, records):
            os.kill(entry['proc'].pid,signal.SIGKILL); assert entry['proc'].wait()==-signal.SIGKILL
            try: os.killpg(entry['proc'].pid,signal.SIGKILL)
            except ProcessLookupError: pass
            def direct_gone():
                for record in records:
                    try: os.kill(record['wrapperPid'],0)
                    except ProcessLookupError: continue
                    return False
                return True
            self.until(direct_gone,'direct backend wrappers gone')
            control=self.dir/(entry['writer']+'-control'); (control/'ping').touch()
            self.until(lambda:len(list(control.glob('*.alive')))==2,'detached workers acknowledge after group death')
            assert {int(p.read_text()) for p in control.glob('*.alive')}=={r['workerPid'] for r in records}
            mark(self.name,'direct-group-gone-detached-workers-alive',directWrappersAbsent=True,detachedAcknowledgments=2)

        def wait_escaped(self, records):
            def gone():
                for record in records:
                    try: os.kill(record['workerPid'],0)
                    except ProcessLookupError: continue
                    return False
                return True
            self.until(gone,'escaped real native compilers exit')
            mark(self.name,'escaped-backends-exited',jobs=2)

        def close(self):
            groups={entry['proc'].pid for entry in self.processes}
            groups.update(r['workerGroup'] for r in self.records)
            for group in groups:
                try: os.killpg(group,signal.SIGKILL)
                except ProcessLookupError: pass
            for entry in self.processes: entry['proc'].wait()

    case=Fixture('root-alias','root-alias')
    try:
        a=case.start('a-build','a'); case.capture(a)
        case.finish(case.start('b-alias-contended','b'),status=70,cause='Output namespace occupied',compile_count=0)
        assert not list((case.dir/'b-control').glob('*.ready'))
        mark(case.name,'same-directory-claim',samePhysicalRoot=case.libs['a'].resolve()==case.libs['b'].resolve())
        case.release('a'); case.finish(a)
        b=case.start('b-after-release','b'); case.capture(b); case.release('b'); case.finish(b)
        case.finish(case.start('b-runtime','b',runtime=43))
    finally: case.close()

    case=Fixture('descendant-alias','descendant-alias')
    try:
        a=case.start('a-build','a');case.capture(a)
        b=case.start('b-build','b');case.capture(b)
        assert all((lib/'.experimental-native-write-lease').is_dir() for lib in case.libs.values())
        mark(case.name,'two-claims-one-write-set',distinctCanonicalRoots=True,samePhysicalModuleDirectory=True)
        case.release('b');case.finish(b);case.finish(case.start('runtime-before-a','b',runtime=43))
        before=case.inventory('b');case.release('a');case.finish(a,status=70,cause='Native build inputs changed')
        after=case.inventory('b')
        for name in ['middle.native-complete','middle.native-source','middle.native-interface']: assert before[name]==after[name]
        assert any(before[name]!=after[name] for name in ['middle.o1','middle~0.o1'])
        case.finish(case.start('b-warm','b',force=False),compile_count=0)
        case.finish(case.start('runtime-after-a','b',runtime=42))
        mark(case.name,'root-canonicalization-insufficient',receiptUnchanged=True,objectsChanged=True)
    finally:case.close()

    for mode in ['shared','generations']:
        case=Fixture('escaped-'+mode,mode,detached=True)
        try:
            a=case.start('a-build','a');records=case.capture(a)
            case.kill_frontend_and_direct_group(a,records)
            abandoned=case.libs['a']/'.experimental-native-write-lease';assert abandoned.is_dir()
            if mode=='shared':
                case.finish(case.start('b-before-reclamation','b'),status=70,cause='Output namespace occupied',compile_count=0)
                # Deliberately unsafe recovery ONLY in this owned scratch fixture:
                # direct group death is known to leave detached writers alive.
                abandoned.rmdir();mark(case.name,'unsafe-test-reclamation',directGroupOnly=True)
            b=case.start('b-build','b');case.capture(b);case.release('b');case.finish(b)
            case.finish(case.start('runtime-before-old-write','b',runtime=43))
            before=case.inventory('b')
            if mode=='generations':
                active=case.dir/'active.json';pending=active.with_suffix('.pending')
                pending.write_text(json.dumps({'generation':'b','libdir':str(case.libs['b'])}));pending.replace(active)
                pinned=Path(json.loads(active.read_text())['libdir']);active_hash=sha(active)
                mark(case.name,'reader-pins-completed-generation',generation='b',receiptPresent=(pinned/'writers/middle.native-complete').is_file())
            case.release('a');case.wait_escaped(records)
            if mode=='shared':
                after=case.inventory('b')
                for name in ['middle.native-complete','middle.native-source','middle.native-interface']:assert before[name]==after[name]
                assert any(before[name]!=after[name] for name in ['middle.o1','middle~0.o1'])
                case.finish(case.start('b-warm','b',force=False),compile_count=0)
                case.finish(case.start('runtime-after-old-write','b',runtime=42))
            else:
                assert abandoned.is_dir() and before==case.inventory('b') and active_hash==sha(active)
                assert not (case.libs['a']/'writers/middle.native-complete').exists()
                case.finish(case.start('old-private-runtime','a',runtime=42))
                case.finish(case.start('pinned-runtime-after-old-write','b',runtime=43,pinned=pinned))
                case.finish(case.start('b-warm','b',force=False),compile_count=0)
                mark(case.name,'old-writes-confined-to-private-generation',oldClaimRetained=True,activePointerUnchanged=True,activeObjectsUnchanged=True)
        finally:case.close()
    report=dict(schema='asp.native-namespace-study.v1',patchedSourceSha256=patched_hash,
                instrumentedSourceSha256=sha(source),patchSha256=sha(args.patch),nativeGscSha256=sha(args.native_gsc),
                retainedCompilerPatchChanged=False,observations=observations)
    (args.output/'study.json').write_text(json.dumps(report,indent=2)+'\n')
print('NAMESPACE-ALIASES-ESCAPED-BACKENDS-AND-GENERATIONS-STUDIED',flush=True)
