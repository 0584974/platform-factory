from pathlib import Path
import yaml

ROOT = Path(__file__).parents[1]

def test_required_layout_exists():
    required = [
        ROOT / 'terraform/modules/vm/main.tf',
        ROOT / 'terraform/environments/dev/main.tf',
        ROOT / 'ansible/playbooks/base.yml',
        ROOT / 'ansible/playbooks/harden.yml',
        ROOT / 'packer/linux.pkr.hcl',
        ROOT / 'packer/windows.pkr.hcl',
        ROOT / 'policies/os-catalog.yml',
    ]
    assert all(p.exists() for p in required)


def test_os_catalogue_has_requested_families():
    data = yaml.safe_load((ROOT / 'policies/os-catalog.yml').read_text())
    assert {'ubuntu','debian','oracle_linux','sles'} <= set(data['linux'])
    assert set(data['windows']['server']['supported']) == {'2022','2025'}
    assert set(data['windows']['client']['supported']) == {'10','11'}
