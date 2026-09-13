# vSphere OS image factory

This directory builds VMware vSphere golden templates directly from operating-system installation media using Packer's `vsphere-iso` builder. Terraform then clones the resulting templates and the common Ansible layer applies environment-specific configuration and hardening.

```text
ISO -> unattended installer -> VMware Tools -> Packer cleanup -> vSphere template
    -> Terraform clone -> generated Ansible inventory -> baseline -> hardening
```

## Image profiles

Linux profiles:

- Ubuntu 24.04 LTS — Subiquity autoinstall / NoCloud HTTP seed
- Debian 12 — Debian Installer preseed
- Oracle Linux 9 — Anaconda Kickstart
- SLES 15 — AutoYaST

Windows profiles:

- Windows Server 2022
- Windows Server 2025
- Windows 10 Pro
- Windows 11 Pro

The Windows guest IDs follow vSphere's current identifiers: Server 2022 uses `windows2019srvNext_64Guest`, Server 2025 uses `windows2022srvNext_64Guest`, Windows 10 uses `windows9_64Guest`, and Windows 11 uses `windows11_64Guest`.

## Secrets

Do not write passwords into `.pkrvars.hcl` files. Packer automatically accepts `PKR_VAR_<variable>` environment variables.

Linux example:

```bash
cd packer/vsphere
cp profiles/common.pkrvars.hcl.example profiles/common.pkrvars.hcl
cp profiles/ubuntu-24.04.pkrvars.hcl.example profiles/ubuntu-24.04.pkrvars.hcl

export PKR_VAR_vsphere_password='...'
export PKR_VAR_ssh_password='temporary-build-password'
export PKR_VAR_ssh_password_hash="$(openssl passwd -6 "$PKR_VAR_ssh_password")"

packer init linux.pkr.hcl
packer build \
  -var-file=profiles/common.pkrvars.hcl \
  -var-file=profiles/ubuntu-24.04.pkrvars.hcl \
  linux.pkr.hcl
```

Windows example:

```bash
cd packer/vsphere
cp profiles/common.pkrvars.hcl.example profiles/common.pkrvars.hcl
cp profiles/windows-common.pkrvars.hcl.example profiles/windows-common.pkrvars.hcl
cp profiles/windows-server-2025.pkrvars.hcl.example profiles/windows-server-2025.pkrvars.hcl

export PKR_VAR_vsphere_password='...'
export PKR_VAR_winrm_password='temporary-build-password'

packer init windows.pkr.hcl
packer build \
  -var-file=profiles/common.pkrvars.hcl \
  -var-file=profiles/windows-common.pkrvars.hcl \
  -var-file=profiles/windows-server-2025.pkrvars.hcl \
  windows.pkr.hcl
```

## ISO and edition values

The example ISO datastore paths and checksums are placeholders. Pin organization-approved ISO files and SHA-256 checksums before production use. For Windows, verify the exact WIM image name in your media before build, for example with `dism /Get-WimInfo /WimFile:X:\sources\install.wim`, then set `image_name` in the profile.

## Installer notes

Boot menus vary between point releases, BIOS/EFI settings and customized installation media. The supplied boot commands are starting points for standard vendor media and should be smoke-tested against the exact ISO version used by the organization. The unattended answer files deliberately configure only the minimum build account and packages needed to produce a manageable template. Final security policy belongs to the Ansible hardening stage.

SLES installations can require organization-specific registration/repository configuration. Add SCC/RMT credentials at runtime or use internally mirrored media; never commit registration codes.

Windows builds attach a separate configuration CD and optionally a VMware Tools ISO. `SetupComplete.ps1` enables WinRM with NTLM for the build channel and installs VMware Tools when `setup64.exe` is available. The Ansible Windows hardening role is responsible for the final remote-management and firewall policy after provisioning.

## Validation versus end-to-end testing

GitHub Actions validates Packer HCL syntax and answer-file structure without vCenter credentials. An end-to-end image build still requires a real vSphere lab, licensed/approved installation media and reachable guest networking. A green syntax pipeline therefore means the definitions are structurally valid, not that every vendor installer boot sequence has been exercised on every ISO revision.
