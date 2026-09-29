"""Download a pinned test core from GitHub and verify its release-API SHA256."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import tempfile
import urllib.request

TAG = 'v1.19.31'
NAME = f'mihomo-linux-amd64-compatible-{TAG}.gz'

def fetch(url):
    headers = {'User-Agent': 'agent-skills-regression-tests'}
    token = os.environ.get('GH_TOKEN')
    if token and url.startswith('https://api.github.com/'):
        headers['Authorization'] = f'Bearer {token}'
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60) as response:
        return response.read()

def main():
    release = json.loads(fetch(f'https://api.github.com/repos/MetaCubeX/mihomo/releases/tags/{TAG}'))
    matches = [a for a in release['assets'] if a['name'] == NAME]
    if len(matches) != 1:
        raise RuntimeError('Expected exactly one official compatible Linux asset')
    asset = matches[0]
    digest = asset.get('digest', '')
    if not digest or not digest.startswith('sha256:') or len(digest) != 71:
        raise RuntimeError('Official SHA256 unavailable; refusing an unverified test binary')
    data = fetch(asset['browser_download_url'])
    if hashlib.sha256(data).hexdigest() != digest.removeprefix('sha256:'):
        raise RuntimeError('Release binary SHA256 mismatch')
    directory = Path(tempfile.mkdtemp(prefix='mihomo-core-'))
    path = directory / 'mihomo'
    path.write_bytes(gzip.decompress(data))
    path.chmod(0o700)
    if os.environ.get('GITHUB_ENV'):
        with open(os.environ['GITHUB_ENV'], 'a', encoding='utf-8') as output:
            output.write(f'MIHOMO_CORE={path}\n')
    print(f'Verified {NAME}; MIHOMO_CORE={path}')

if __name__ == '__main__':
    main()
