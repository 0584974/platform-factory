# platform-factory

GitHub-ready reference implementation for creating a VM platform from code:

**Packer image build -> Terraform VM/network/storage -> bootstrap -> Ansible configuration -> hardening -> validation**

The default example targets libvirt/KVM so it can be demonstrated without cloud credentials. Provider-specific modules can be added for Azure, AWS, VMware or Proxmox while keeping the Ansible layer unchanged.

## Supported OS catalogue

- Ubuntu 22.04 / 24.04 LTS
- Debian 12 / 13
- Oracle Linux 8 / 9
- SLES 15
- Windows Server 2022 / 2025
- Windows 10 / 11

Linux guests use cloud-init when an official cloud image exists. Windows guests are designed for a Packer-built image with Unattend + WinRM bootstrap. No proprietary OS image is stored in this repository.

## Repository flow

```text
packer/ -> golden image
terraform/ -> VM + network + disk + generated inventory
ansible/playbooks/base.yml -> baseline configuration
ansible/playbooks/harden.yml -> OS hardening
ansible/playbooks/validate.yml -> post-build checks
```

## Safety

The sample environment creates only explicitly declared VMs and does not contain credentials or destructive production defaults. Production state, secrets and provider authentication belong outside the repository.
