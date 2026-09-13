# platform-factory

GitHub-ready reference implementation for creating a VM platform from code:

**Packer image build -> Terraform VM/network/storage -> bootstrap -> Ansible configuration -> hardening -> validation**

Two provider paths are currently included:

- **libvirt/KVM** — lightweight demonstration path without cloud credentials.
- **VMware vSphere** — vCenter/vSphere provisioning plus a Packer `vsphere-iso` image-factory path for unattended OS installation.

Provider-specific modules for Azure, AWS and Proxmox can be added without changing the Ansible operating-system layer.

## Supported OS catalogue

- Ubuntu 22.04 / 24.04 LTS
- Debian 12 / 13
- Oracle Linux 8 / 9
- SLES 15
- Windows Server 2022 / 2025
- Windows 10 / 11

The first vSphere image-factory profiles currently implement Ubuntu 24.04, Debian 12, Oracle Linux 9, SLES 15, Windows Server 2022/2025 and Windows 10/11. Linux uses the native unattended installer for each distribution; Windows uses Unattend + WinRM. No proprietary OS image or credential is stored in this repository.

## Repository flow

```text
ISO
  -> Packer unattended OS build
  -> vSphere golden template
  -> Terraform clone + network/storage
  -> generated Ansible inventory
  -> baseline configuration
  -> hardening
  -> validation
```

### libvirt/KVM

```bash
cd terraform/environments/dev
terraform init
terraform plan
```

### VMware vSphere provisioning

```bash
export TF_VAR_vsphere_server='vcenter.example.com'
export TF_VAR_vsphere_user='svc-terraform@vsphere.local'
export TF_VAR_vsphere_password='...'
cd terraform/environments/vsphere
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

See [`docs/vsphere.md`](docs/vsphere.md) for Terraform provisioning and [`packer/vsphere/README.md`](packer/vsphere/README.md) for unattended golden-image creation from ISO media.

## Safety

The sample environments create only explicitly declared VMs and do not contain credentials or destructive production defaults. Production state, secrets and provider authentication belong outside the repository.
