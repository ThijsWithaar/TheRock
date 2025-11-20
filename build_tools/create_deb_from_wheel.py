#!/usr/bin/env python3
"""
Convert a python wheel into a debian (binary) packages.

Builds a folder structure into a temporary directory,
fills in the debian/control file,
and then uses dpkg-deb to create a .deb file
"""

from pathlib import Path
import tempfile
import zipfile
import shutil
import argparse
import subprocess

from email.parser import Parser
#from pip._vendor.packaging.tags import parse_tag


# Convert packages names from pip to apt, using heuristics
# https://packages.debian.org/search
def pip2apt(pip_name:str):
    apt_name = f'python3-{pip_name.replace('_','-')}'
    if pip_name in ['scipy', 'numpy', 'optree', 'ml_dtypes', 'jaxlib', 'jax-rocm60-pjrt']:
        return apt_name
    if pip_name == 'pyyaml':
        return 'python3-yaml'
    elif subprocess.run(['apt-cache','show', apt_name],
                        stderr=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL).returncode == 0:
        return apt_name
    return None

def parse_version(verstr:str) -> tuple:
    """
    Parse wheel versions, for example:
        'jaxlib==0.6.0; extra == "minimum-jaxlib"',
        'jaxlib<=0.6.1,>=0.6.0; extra == "tpu"',
        'numpy>=1.25'

    Returns: name, version, comparison
    """
    def debcmp(pipcmp):
        """"Convert pip- to deb-comparators"""
        if pipcmp == '==':
            return '='
        return pipcmp

    # primary, without any extras
    prim = verstr.split(';')[0] if ';' in verstr else verstr
    # The first version requirement
    hd = verstr.split(',')[0] if ',' in prim else prim
    cmps = ['>=', '=='] # '<=', '!='
    for cmp in cmps:
        if cmp in hd:
            name, version = hd.split(cmp)
            return name.rstrip(), version, debcmp(cmp)
    if all(c.isalnum() for c in hd):
        return hd, None, None # No version specified
    return None, None, None

def read_whl_meta(fn:Path):
    # https://github.com/pypa/pip/issues/12884#issuecomment-2261220441
    with open(fn,'r') as f:
        wheel = f.read()
        return Parser().parsestr(wheel)

def write_whl_meta(fnDst:Path, d:list):
    """
    Write a list of [key, value] pairs to a semi-colon separated file
    """
    with open(fnDst, 'w') as f:
        for k,v in d:
            f.write(f'{k}: {v}\n')

def build_deb(ptGen, ptDst, fnWheel):
    ptSite = ptGen / 'usr'/'lib'/'python3'/'dist-packages'
    ptSite.mkdir(parents=True)
    with zipfile.ZipFile(fnWheel, 'r') as zip_ref:
        zip_ref.extractall(ptSite)

    ptControl = ptGen / 'DEBIAN'
    ptControl.mkdir()
    
    with open(ptControl / 'postinst', 'w') as f:
        pass
    (ptControl / 'postinst').chmod(0o775)
    with open(ptControl / 'prerm', 'w') as f:
        pass
    (ptControl / 'prerm').chmod(0o775)

    # Parse metadata, convert to debian control-file
    ptMeta = next(ptSite.glob('*.dist-info/METADATA'))
    meta = read_whl_meta(ptMeta)
    package_name = 'python3-' + meta["Name"].replace('_','-')
    # Get at least some of the dependencies
    depends_dict = {}
    for req_dist in meta.get_all('Requires-Dist', []):
        #print(f'req_dist = {req_dist}')
        pip_name, ver, cmp = parse_version(req_dist)
        #print(f'\tname {pip_name}, ver {ver}, cmp {cmp}')
        if pip_name is not None:
            apt_name = pip2apt(pip_name)
            if apt_name is not None:
                if ver is not None:
                    depends_dict[apt_name] = (cmp, ver) # ToDo: check on most resricting version
                elif apt_name not in depends_dict:
                    depends_dict[apt_name] = None
            else:
                print(f"Dependency '{pip_name}', version '{ver}' has no known apt equivalent")

    depends = []
    for apt_name, cmp_ver in depends_dict.items():
        if cmp_ver is not None:
            depends.append(f'{apt_name} ({cmp_ver[0]} {cmp_ver[1]})')
        else:
            depends.append(f'{apt_name}')

    depends_str = ', '.join(depends)
    print(f'Dependencies: {depends_str}')

    arch = 'amd64'
    control = [
        ['Architecture', arch],
        ['Depends', depends_str],
        ['Description', meta['Summary']],
        ['Maintainer', f'{meta["Author"]} <{meta["Author-email"]}>' ],
        ['Package', package_name],
        ['Priority', 'optional'],
        ['Section', 'devel'],
        ['Version', meta['Version']],
    ]
    write_whl_meta(ptControl / 'control', control)

    #print(f"Generating {meta["Name"]} in {ptGen}"); import pdb; pdb.set_trace()

    # The dist-info is not part of a .deb:
    ptDistInfo = next(ptSite.glob('*.dist-info'))
    shutil.rmtree(ptDistInfo)

    cmd = ['dpkg-deb', '--root-owner-group', '-b', ptGen, ptDst / f'{package_name}-{meta['Version']}_{arch}.deb']
    subprocess.run(cmd)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='create_deb_from_wheel')
    parser.add_argument("out", help="output folder")
    parser.add_argument("wheel", nargs='+', help="wheel(s) to convert")
    
    args = parser.parse_args()
    wheels = args.wheel
    out = args.out

    #wheels = ['./build/jax/dist/jaxlib-0.6.1.dev20250510-cp313-cp313-manylinux2014_x86_64.whl']
    #out = './build/out/'

    for wheel in wheels:
        with tempfile.TemporaryDirectory() as tmpdirname:
            ptGen = Path(tmpdirname)
            build_deb(ptGen, Path(out), Path(wheel))
