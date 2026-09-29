"""Opt-in real-core tests: loopback only, no TUN, no real subscription.
Set MIHOMO_CORE to a verified executable. Missing core is SKIP, never PASS.
"""
import contextlib
import copy
import json
import os
from pathlib import Path
import secrets
import socket
import struct
import subprocess
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
import yaml
from test_static import load_config

CORE = os.environ.get('MIHOMO_CORE', '')
HTTP = urllib.request.build_opener(urllib.request.ProxyHandler({}))

def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]

class Core:
    def __init__(self, rules=None, initial='JP fixture'):
        self.temp = tempfile.TemporaryDirectory(prefix='mihomo-fixture-')
        self.root = Path(self.temp.name)
        self.port, self.api = free_port(), free_port()
        while self.api == self.port:
            self.api = free_port()
        self.secret = secrets.token_hex(24)
        self.nodes = self.root / 'nodes.yaml'
        self.set_nodes(initial)
        self.services = self.root / 'services.list'
        self.services.write_text('DOMAIN,localhost\n', encoding='utf-8')
        self.config = {
            'mixed-port': self.port, 'bind-address': '127.0.0.1', 'allow-lan': False,
            'mode': 'rule', 'ipv6': False, 'log-level': 'debug',
            'external-controller': f'127.0.0.1:{self.api}', 'secret': self.secret,
            'tun': {'enable': False}, 'dns': {'enable': False},
            'proxies': [{'name': 'TCPONLY', 'type': 'socks5', 'server': '127.0.0.1', 'port': 9, 'udp': False}],
            'proxy-providers': {'subscription': {'type': 'file', 'path': str(self.nodes), 'health-check': {'enable': False}}},
            'proxy-groups': [{'name': 'US', 'type': 'fallback', 'use': ['subscription'], 'filter': '^US', 'empty-fallback': 'REJECT', 'url': 'http://127.0.0.1:9/', 'interval': 0}],
            'rule-providers': {'services': {'type': 'file', 'behavior': 'classical', 'format': 'text', 'path': str(self.services)}},
            'rules': rules or ['MATCH,DIRECT'],
        }
        self.process = None
        self.log = None

    def set_nodes(self, name):
        self.nodes.write_text(yaml.safe_dump({'proxies': [{'name': name, 'type': 'socks5', 'server': '127.0.0.1', 'port': 9, 'udp': False}]}), encoding='utf-8')

    def request(self, path, method='GET'):
        request = urllib.request.Request(f'http://127.0.0.1:{self.api}{path}', headers={'Authorization': f'Bearer {self.secret}'}, method=method)
        with HTTP.open(request, timeout=2) as response:
            payload = response.read()
        return json.loads(payload) if payload else None

    def __enter__(self):
        path = self.root / 'config.yaml'
        path.write_text(yaml.safe_dump(self.config), encoding='utf-8')
        self.log = (self.root / 'core.log').open('w+', encoding='utf-8')
        self.process = subprocess.Popen([CORE, '-d', str(self.root), '-f', str(path)], stdout=self.log, stderr=subprocess.STDOUT)
        limit = time.monotonic() + 15
        while time.monotonic() < limit:
            try:
                self.request('/version')
                return self
            except (OSError, urllib.error.URLError):
                if self.process.poll() is not None:
                    break
                time.sleep(0.1)
        self.log.flush()
        diagnostic = (self.root / 'core.log').read_text(encoding='utf-8')
        self.__exit__(None, None, None)
        raise AssertionError('Core startup failed: ' + diagnostic)

    def __exit__(self, *_):
        if self.process is not None and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=5)
        if self.log:
            self.log.close()
        self.temp.cleanup()

@contextlib.contextmanager
def echo_server():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('127.0.0.1', 0))
    sock.settimeout(0.1)
    stop = threading.Event()
    def echo():
        while not stop.is_set():
            try:
                payload, peer = sock.recvfrom(65535)
                sock.sendto(payload, peer)
            except socket.timeout:
                pass
            except OSError:
                break
    thread = threading.Thread(target=echo, daemon=True)
    thread.start()
    try:
        yield sock.getsockname()[1]
    finally:
        stop.set()
        thread.join(timeout=1)
        sock.close()

def read_exact(sock, count):
    data = b''
    while len(data) < count:
        chunk = sock.recv(count - len(data))
        if not chunk:
            raise AssertionError('SOCKS connection closed early')
        data += chunk
    return data

def udp_probe(core, destination, port):
    with socket.create_connection(('127.0.0.1', core.port), timeout=3) as control:
        control.sendall(b'\x05\x01\x00')
        if read_exact(control, 2) != b'\x05\x00':
            raise AssertionError('SOCKS authentication failed')
        control.sendall(b'\x05\x03\x00\x01' + b'\x00' * 6)
        head = read_exact(control, 4)
        if head[:2] != b'\x05\x00' or head[3] != 1:
            raise AssertionError(f'Unexpected UDP associate reply: {head!r}')
        address = socket.inet_ntoa(read_exact(control, 4))
        relay_port = struct.unpack('!H', read_exact(control, 2))[0]
        if address == '0.0.0.0':
            address = '127.0.0.1'
        marker = secrets.token_bytes(16)
        if destination == 'localhost':
            target = b'\x03\x09localhost'
        else:
            target = b'\x01' + socket.inet_aton(destination)
        packet = b'\x00\x00\x00' + target + struct.pack('!H', port) + marker
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
            udp.settimeout(1)
            udp.sendto(packet, (address, relay_port))
            try:
                reply, _ = udp.recvfrom(65535)
                return reply.endswith(marker)
            except socket.timeout:
                return False

@unittest.skipUnless(CORE, 'MIHOMO_CORE is not set; real-core tests not run')
class CoreTests(unittest.TestCase):
    def test_template_parses_with_local_providers(self):
        config = copy.deepcopy(load_config())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config['tun']['enable'] = False
            config['dns']['enable'] = False
            for name, provider in config['proxy-providers'].items():
                path = root / f'proxy-{name}.yaml'
                path.write_text(yaml.safe_dump({'proxies': [{'name': 'US fixture', 'type': 'socks5', 'server': '127.0.0.1', 'port': 9, 'udp': False}]}), encoding='utf-8')
                config['proxy-providers'][name] = {'type': 'file', 'path': str(path), 'health-check': {'enable': False}}
            for name, provider in config['rule-providers'].items():
                path = root / f'rule-{name}.list'
                path.write_text('127.0.0.0/8\n' if provider['behavior'] == 'ipcidr' else 'DOMAIN,fixture.test\n', encoding='utf-8')
                config['rule-providers'][name] = {'type': 'file', 'behavior': provider['behavior'], 'format': 'text', 'path': str(path)}
            for group in config['proxy-groups']:
                if 'url' in group:
                    group['url'] = 'http://127.0.0.1:9/'
                    group['interval'] = 0
            path = root / 'config.yaml'
            path.write_text(yaml.safe_dump(config, allow_unicode=True), encoding='utf-8')
            result = subprocess.run([CORE, '-t', '-d', directory, '-f', str(path)], capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_empty_group_and_provider_update(self):
        with Core(initial='JP fixture') as core:
            self.assertEqual(core.request('/proxies/US')['now'], 'REJECT')
            core.set_nodes('US fixture')
            core.request('/providers/proxies/subscription', 'PUT')
            self.assertEqual(core.request('/proxies/US')['now'], 'US fixture')
            core.set_nodes('JP fixture')
            core.request('/providers/proxies/subscription', 'PUT')
            self.assertEqual(core.request('/proxies/US')['now'], 'REJECT')

    def check_guard(self, match):
        first = f'{match},TCPONLY'
        guard = f'AND,((NETWORK,udp),({match})),REJECT'
        with echo_server() as port:
            # The unguarded baseline proves this would be a real DIRECT escape.
            with Core(rules=[first, 'MATCH,DIRECT']) as core:
                self.assertTrue(udp_probe(core, 'localhost', port), 'Baseline did not reach the loopback echo server')
            with Core(rules=[first, guard, 'MATCH,DIRECT']) as core:
                self.assertTrue(udp_probe(core, '127.0.0.1', port), 'Unrelated UDP was blocked')
                self.assertFalse(udp_probe(core, 'localhost', port), 'Protected UDP escaped to DIRECT')

    def test_domain_udp_guard(self):
        self.check_guard('DOMAIN,localhost')

    def test_ruleset_udp_guard(self):
        self.check_guard('RULE-SET,services')

if __name__ == '__main__':
    unittest.main()
