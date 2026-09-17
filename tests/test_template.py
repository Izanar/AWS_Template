"""Offline regression checks. Never invoke Terraform apply or contact AWS."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]


class TemplateTests(unittest.TestCase):
    def test_ec2_has_no_unused_password_secret(self):
        for name in ('main.tf', 'outputs.tf'):
            content = (ROOT / 'src/ec2' / name).read_text()
            self.assertNotIn('aws_secretsmanager_secret', content)
            self.assertNotIn('app_password', content)

    def test_manifest_paths_exist(self):
        path = ROOT / 'ansible/playbooks/eks-deploy.yml'
        play = yaml.safe_load(path.read_text())[0]
        for manifest in play['vars']['kubernetes_manifests']:
            resolved = Path(manifest.replace('{{ playbook_dir }}', str(path.parent)))
            self.assertTrue(resolved.is_file(), resolved)

    def test_service_selects_deployment(self):
        for scenario in ('base', 'local'):
            base = ROOT / 'kubernetes' / scenario
            deployment = yaml.safe_load((base / 'deployment.yaml').read_text())
            service = yaml.safe_load((base / 'service.yaml').read_text())
            self.assertEqual(service['spec']['selector'],
                             deployment['spec']['template']['metadata']['labels'])
            self.assertEqual(service['metadata']['namespace'],
                             deployment['metadata']['namespace'])

    def test_unknown_scenario_stops_before_terraform(self):
        for script in ('deploy.sh', 'destroy.sh'):
            result = subprocess.run(['bash', str(ROOT / 'scripts' / script), '../ec2'],
                                    input='', text=True, capture_output=True, timeout=10)
            self.assertNotEqual(result.returncode, 0)

    def test_local_preflight_stops_before_terraform_without_systemd(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            marker = directory / 'terraform-called'
            for name, body in {
                'ps': 'echo init',
                'terragrunt': f'touch "{marker}"; exit 99',
            }.items():
                executable = directory / name
                executable.write_text('#!/bin/sh\n' + body + '\n')
                executable.chmod(0o755)
            env = dict(os.environ, PATH=str(directory) + ':' + os.environ['PATH'])
            result = subprocess.run(['bash', str(ROOT / 'scripts/deploy.sh'), 'local-wsl'],
                                    env=env, input='', text=True, capture_output=True, timeout=10)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Enable systemd', result.stderr)
            self.assertFalse(marker.exists())

    def test_workflow_rejects_missing_state_and_unconfirmed_apply(self):
        workflow = yaml.safe_load((ROOT / '.github/workflows/deploy.yml').read_text())
        steps = workflow['jobs']['deploy']['steps']
        guard = next(step['run'] for step in steps if step['name'].startswith('Require persistent'))
        for action, confirm, bucket, expected in [
            ('apply', 'false', 'existing', 1),
            ('destroy', 'false', '', 1),
            ('apply', 'true', 'existing', 0),
            ('destroy', 'false', 'existing', 0),
        ]:
            env = dict(os.environ, ACTION=action, CONFIRM_COSTS=confirm,
                       TF_STATE_BUCKET=bucket, TF_STATE_REGION='eu-central-1', TF_LOCK_TABLE='existing')
            result = subprocess.run(['bash', '-e', '-c', guard], env=env,
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
