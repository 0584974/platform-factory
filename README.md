# platform-factory

GitHub-ready reference implementation for creating a VM platform from code:

**Packer image build -> Terraform VM/network/storage -> bootstrap -> Ansible configuration -> hardening -> validation**

Two provider paths are currently included:

- **libvirt/KVM** — lightweight demonstration path without cloud credentials.
- **VMware vSphere** — real vCenter/vSphere provisioning by cloning organization-approved VM templates and passing them to the same Ansible baseline/hardening layer.

Provider-specific modules for Azure, AWS and Proxmox can be added without changing the Ansible operating-system layer.

## Supported OS catalogue

- Ubuntu 22.04 / 24.04 LTS
- Debian 12 / 13
- Oracle Linux 8 / 9
- SLES 15
- Windows Server 2022 / 2025
- Windows 10 / 11

Linux guests use cloud-init where appropriate. Windows guests are designed around an Unattend + WinRM bootstrap. No proprietary OS image is stored in this repository.

## Repository flow

```text
packer/ -> golden image
terraform/ -> VM + network + disk + generated inventory
ansible/playbooks/base.yml -> baseline configuration
ansible/playbooks/harden.yml -> OS hardening
ansible/playbooks/validate.yml -> post-build checks
```

### libvirt/KVM

```bash
cd terraform/environments/dev
terraform init
terraform plan
```

### VMware vSphere

```bash
export TF_VAR_vsphere_server='vcenter.example.com'
export TF_VAR_vsphere_user='svc-terraform@vsphere.local'
export TF_VAR_vsphere_password='...'
cd terraform/environments/vsphere
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

See [`docs/vsphere.md`](docs/vsphere.md) for prerequisites, template requirements and the image-to-VM workflow.

## Safety

The sample environments create only explicitly declared VMs and do not contain credentials or destructive production defaults. Production state, secrets and provider authentication belong outside the repository.
