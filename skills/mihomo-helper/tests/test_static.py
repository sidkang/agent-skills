"""Offline template invariants. Does not start mihomo or access the network."""
from pathlib import Path
import re
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'references/config.yaml'
BUILTINS = {'DIRECT', 'REJECT', 'REJECT-DROP', 'PASS', 'COMPATIBLE'}
REGIONS = ['US', 'JP', 'TW', 'HK', 'SG', 'OTHER']

class UniqueLoader(yaml.SafeLoader):
    pass

def unique_mapping(loader, node, deep=False):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in result:
            raise ValueError(f'Duplicate YAML key: {key}')
        result[key] = loader.construct_object(value_node, deep=deep)
    return result

UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)

def load_config():
    return yaml.load(CONFIG.read_text(encoding='utf-8'), Loader=UniqueLoader)

class StaticTests(unittest.TestCase):
    def setUp(self):
        self.config = load_config()
        self.groups = {g['name']: g for g in self.config['proxy-groups']}
        self.rules = self.config['rules']

    def test_duplicate_keys_rejected(self):
        with self.assertRaises(ValueError):
            yaml.load('a: 1\na: 2\n', Loader=UniqueLoader)

    def test_group_names_unique(self):
        names = [g['name'] for g in self.config['proxy-groups']]
        self.assertEqual(len(names), len(set(names)))
        self.assertFalse(set(names) & BUILTINS)

    def test_references(self):
        targets = set(self.groups) | BUILTINS | {p['name'] for p in self.config.get('proxies', [])}
        for group in self.groups.values():
            for target in group.get('proxies', []):
                self.assertIn(target, targets)
            for provider in group.get('use', []):
                self.assertIn(provider, self.config['proxy-providers'])
        for rule in self.rules:
            parts = rule.split(',')
            target = parts[-2] if parts[-1] == 'no-resolve' else parts[-1]
            self.assertIn(target, targets, rule)
            for provider in re.findall(r'RULE-SET,([^,)]+)', rule):
                self.assertIn(provider, self.config['rule-providers'], rule)

    def test_group_graph_acyclic(self):
        def walk(name, stack):
            self.assertNotIn(name, stack, f'Group cycle: {stack + [name]}')
            for child in self.groups[name].get('proxies', []):
                if child in self.groups:
                    walk(child, stack + [name])
        for name in self.groups:
            walk(name, [])

    def test_empty_groups_reject(self):
        for name in ['AUTO'] + REGIONS:
            self.assertEqual(self.groups[name]['empty-fallback'], 'REJECT')
        for group in self.groups.values():
            if group.get('use'):
                self.assertEqual(group.get('empty-fallback'), 'REJECT')

    def test_region_defaults_preserved(self):
        self.assertEqual(self.groups['GOOGLE']['proxies'][0], 'JP')
        self.assertEqual(self.groups['CHATGPT']['proxies'][0], 'US')
        for name in REGIONS:
            self.assertEqual(self.groups[name]['type'], 'fallback')
        self.assertEqual(self.groups['AUTO']['type'], 'url-test')
        self.assertNotIn('DIRECT', self.groups['GOOGLE']['proxies'])
        self.assertNotIn('DIRECT', self.groups['CHATGPT']['proxies'])

    def test_same_scope_udp_guards(self):
        expected = []
        for i, rule in enumerate(self.rules):
            if rule.startswith('AND,'):
                continue
            parts = rule.split(',')
            target_index = -2 if parts[-1] == 'no-resolve' else -1
            if parts[target_index] in {'DIRECT', 'REJECT'}:
                continue
            self.assertEqual(target_index, -1, 'Add explicit guard support for new rule options')
            guard = f'AND,((NETWORK,udp),({rule.rsplit(",", 1)[0]})),REJECT'
            self.assertLess(i + 1, len(self.rules))
            self.assertEqual(self.rules[i + 1], guard)
            expected.append(guard)
        self.assertTrue(expected)
        self.assertEqual([r for r in self.rules if r.startswith('AND,')], expected)

    def test_local_exceptions_precede_services(self):
        self.assertEqual(self.rules[:3], ['DOMAIN,localhost,DIRECT', 'DOMAIN-SUFFIX,lan,DIRECT', 'DOMAIN-SUFFIX,local,DIRECT'])
        self.assertIn('community-wide', CONFIG.read_text(encoding='utf-8'))

    def test_final_direct(self):
        self.assertEqual(self.rules[-1], 'MATCH,DIRECT')
        self.assertEqual(sum(r.startswith('MATCH,') for r in self.rules), 1)

    def test_safe_template_defaults(self):
        self.assertFalse(self.config['allow-lan'])
        self.assertNotIn('external-controller', self.config)
        self.assertNotIn('secret', self.config)
        self.assertEqual(self.config['mode'], 'rule')
        self.assertEqual(self.config['proxy-providers']['subscription']['url'], 'https://replace.example/subscription.yaml')
        self.assertEqual(self.config['dns']['enhanced-mode'], 'fake-ip')

    def test_version_and_local_links(self):
        skill = (ROOT / 'SKILL.md').read_text(encoding='utf-8')
        metadata = yaml.load(skill.split('---', 2)[1], Loader=UniqueLoader)
        self.assertEqual(metadata['metadata']['version'], '0.0.4')
        for path in ROOT.rglob('*.md'):
            for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
                if '://' not in target and not target.startswith('#'):
                    self.assertTrue((path.parent / target.split('#')[0]).exists(), f'{path}: missing {target}')

if __name__ == '__main__':
    unittest.main()
