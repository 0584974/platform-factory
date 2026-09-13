# VMware vSphere provisioning

The vSphere path provisions VMs by cloning existing vSphere templates, then hands the guests to the same Ansible baseline/hardening layer used by the libvirt example.

## Prerequisites

- vCenter / vSphere with API write access.
- Terraform provider `vmware/vsphere` 2.17.x.
- Existing datacenter, cluster, datastore and port group/distributed port group.
- Linux/Windows templates with VMware Tools running so Terraform can obtain guest IP addresses.
- Linux templates should expose SSH for the `automation` account; Windows templates should expose WinRM. Credentials are provided at runtime, not committed.
- The configured VM folder must already exist when `vm_folder` is set.

The current `vmware/vsphere` provider supports vSphere 8.x and 9.x. The free vSphere Hypervisor/ESXi offering is not suitable for this workflow because the provider requires API write access.

## Authentication

Keep credentials outside Terraform files. The vSphere provider accepts its standard environment variables:

```bash
export VSPHERE_SERVER='vcenter.example.com'
export VSPHERE_USER='svc-terraform@vsphere.local'
export VSPHERE_PASSWORD='...'
```

Production environments should keep `allow_unverified_ssl = false` and trust the vCenter certificate.

## Deploy

```bash
cd terraform/environments/vsphere
cp terraform.tfvars.example terraform.tfvars
# edit inventory names/template names only; do not add credentials
terraform init
terraform plan
terraform apply
```

Terraform resolves the vSphere inventory objects, clones each requested VM template, sizes CPU/RAM/disk, attaches the target network and waits for VMware Tools to report an IP address. It then writes `ansible/inventory.vsphere.generated.ini`.

Continue with the common configuration layer:

```bash
cd ../../../ansible
ansible-playbook -i inventory.vsphere.generated.ini playbooks/base.yml
ansible-playbook -i inventory.vsphere.generated.ini playbooks/harden.yml
```

## OS installation / golden images

Terraform intentionally deploys from golden templates rather than attempting an installer inside the VM resource. For fully automated OS installation, build those templates with Packer's VMware vSphere `vsphere-iso` builder (or import organization-approved templates into a content library), then let Terraform clone them. This keeps image lifecycle and VM lifecycle separate and repeatable.

Recommended pipeline:

```text
ISO -> Packer vsphere-iso -> hardened golden template -> Terraform clone
    -> generated Ansible inventory -> baseline -> hardening -> validation
```

Windows templates should use Unattend/WinRM during image creation. Linux templates can use autoinstall/preseed/AutoYaST/Kickstart as appropriate for the distribution.

## Current limitations

- vSphere guest customization/static IP assignment is not yet modeled; current provisioning expects DHCP and VMware Tools.
- Existing VM folders are referenced, not created.
- Packer vSphere ISO templates are the next implementation layer; this Terraform path already consumes resulting templates.
- Datastore clusters, tags, storage policies and content-library template selection are not yet exposed as module inputs.
