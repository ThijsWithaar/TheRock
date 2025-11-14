#!/usr/bin/env python3
"""
Start a .devcontainer/devcontainer.json in an interactive docker session

The session is removed after shutdown, just like a devcontainer in VS-Code
"""

import hashlib
import json
import os
from pathlib import Path
import signal
import string
import subprocess
import sys


def load_devcontainer_json(fn:Path):
    """Load a devcontainer.json, stripping comments"""
    with open(fn, 'r') as f:
        content = ""
        for line in f.readlines():
            if line.lstrip().startswith("//"):
                continue
            content += line + "\n"
    return json.loads(content)


def apply_vars(src, var_dict):
    """Apply the variables to string `str`"""
    src2 = src.replace(':', '_') # string.Template doesn't like the semicolon
    tp = string.Template(src2)
    # Add local environment to the variables:
    for id_ in tp.get_identifiers():
        if id_.startswith('localEnv_'):
            en = id_.split('localEnv_')[1]
            var_dict[id_] = os.getenv(en)
    return tp.substitute(var_dict)


def mount_args(mount:dict, var_dict):
    """Convert mount options from a dictionary to a command-line option"""
    tp = mount['type']
    src = apply_vars(mount['source'], var_dict)
    tgt = mount['target']
    ma = f"type={tp},source={src},target={tgt}"
    return ['--mount', ma]

def dockerfilename_absolute(dc, devcontainer_path:Path):
    df = dc.get('dockerFile')
    if df:
        if not Path(df).is_absolute():
            df = str((devcontainer_path / df).resolve())
    return df

def build_docker(dc:dict, devcontainer_path:Path, tag="devcontainer_py"):
    """Create command line arguments for `docker build`"""
    if not 'build' in dc:
        tag = dc['image']
        return None, tag

    build = dc['build']
    cmd = ['docker','build']
    df = dockerfilename_absolute(dc, devcontainer_path)
    if df:
        cmd.extend(['-f', df])
    target = build.get('target')
    if target:
        cmd.extend(['--target', target])
    # ToDo: opt = dc['build'].get('target')
    cmd.extend(['-t', tag])
    cmd.append('.')
    return cmd, tag


def run_docker(dc, devcontainer_path, tag, args=[]):
    """Create command line arguments for `docker run`"""
    var_dict = {
        'localWorkspaceFolder': str(devcontainer_path.parent.resolve())
    }
    cmd_run = ['docker', 'run', '--rm']
    if len(args) == 0:
        cmd_run.append('-it')
    else:
        cmd_run.append('--init') # This should allow Ctrl-C to work

    if 'runargs' in dc:
        runargs = dc['runargs']
        cmd_run.exend(runargs)

    if 'mounts' in dc:
        for mount in dc['mounts']:
            cmd_run.extend(['--mount', apply_vars(mount, var_dict)])

    if 'workspaceMount' in dc:
        mount = dc['workspaceMount']
        cmd_run.extend(['--mount', apply_vars(mount, var_dict)])
        
    if 'workspaceFolder' in dc:
        wf = dc['workspaceFolder']
        cmd_run.extend(['-w', wf])

    if 'containerEnv' in dc:
        for k,v in dc['containerEnv'].items():
            v = apply_vars(v, var_dict)
            cmd_run.extend(['-e', f'{k}={v}'])

    if 'remoteEnv' in dc:
        for k,v in dc['remoteEnv'].items():
            v = apply_vars(v, var_dict)
            cmd_run.extend(['-e', f'{k}={v}'])

    if 'remoteUser' in dc:
        usr = dc['remoteUser']
        cmd_run.extend(['-u', usr])

    cmd_run.append(tag)
    if args is not None:
        cmd_run.extend(args)
    return cmd_run


def calculate_hash(dc, devcontainer_path):
    m = hashlib.sha256()
    dcs = json.dumps(dc, sort_keys=True, default=str)
    m.update(dcs.encode("utf-8"))
    df = dockerfilename_absolute(dc, devcontainer_path)
    if df is not None:
        with open(df, 'rb') as f:
            m.update(f.read())
    return m.hexdigest()[:8]


# Parse the devcontainer.json
fn = Path('.devcontainer/devcontainer.json')
devcontainer_path = fn.parent
dc = load_devcontainer_json(fn)

dchash = calculate_hash(dc, devcontainer_path)
tag_default = f'devcontainer_{dchash}'

cmd_build, tag = build_docker(dc, devcontainer_path, tag=tag_default)
cmd_run = run_docker(dc, devcontainer_path=fn.parent, tag=tag, args=sys.argv[1:])


# Execute the check-, build- and run-docker commands
rv = subprocess.run(['docker', 'image', 'inspect', tag], 
                    stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL) # No output
if cmd_build is not None and rv.returncode != 0:
    print(' '.join(cmd_build))
    proc_build = subprocess.Popen(cmd_build, stderr=subprocess.STDOUT)
    proc_build.wait() # Non-interactive, but live output

#print(' '.join(cmd_run))
try:
    with subprocess.Popen(cmd_run) as proc_run:
        proc_run.communicate() # Interactive
except KeyboardInterrupt:
    proc_run.send_signal(signal.SIGINT)
exit(proc_run.returncode)
