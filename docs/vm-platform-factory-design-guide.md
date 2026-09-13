# Designing a VM Platform Factory: From Installation Media to a Validated Service

A virtual machine is easy to create manually. A maintainable VM service is harder: the operating-system image, virtual hardware, network attachment, guest configuration, hardening, secrets, and validation all change on different schedules and belong to different owners.

The `platform-factory` repository demonstrates a deliberate separation of those concerns:

```text
approved ISO
  -> Packer unattended build
  -> versioned golden template
  -> Terraform clone and virtual infrastructure
  -> generated Ansible inventory
  -> baseline configuration
  -> hardening
  -> validation
```

This is not just a tool chain. Each transition is a contract. Making those contracts explicit is what turns scripts into a platform.

## 1. Separate image lifecycle from instance lifecycle

The golden image answers: “What is the smallest trusted operating-system baseline from which instances may start?” The instance definition answers: “How many machines, with what CPU, memory, disks, network, and placement, should exist in this environment?”

Do not rebuild an operating system during every Terraform apply. Build a template with Packer, test it, give it an immutable version, and let Terraform clone that version. Benefits include:

- image builds can be reviewed and promoted independently;
- instance deployment is faster and more deterministic;
- rollback can select the previous approved template;
- patching the image does not silently mutate existing instances;
- failures can be attributed to the image, infrastructure, or configuration layer.

HashiCorp's Packer [vSphere ISO builder](https://developer.hashicorp.com/packer/integrations/hashicorp/vsphere/latest/components/builder/vsphere-iso) creates a VM from installation media and can convert it to a template. Terraform's [vSphere provider](https://registry.terraform.io/providers/vmware/vsphere/latest/docs) then manages clones and related virtual infrastructure.

## 2. Make installation media an input, not an assumption

The repository includes profiles for Ubuntu, Debian, Oracle Linux, SLES, Windows Server, and Windows desktop releases. Each family uses its native unattended-installation mechanism: autoinstall, preseed, Kickstart, AutoYaST, or Unattend.

An image profile should pin:

- the organization-approved ISO path;
- a SHA-256 checksum;
- firmware and virtual hardware compatibility;
- OS edition or WIM image name;
- disk and boot configuration;
- the temporary build communicator;
- guest tools installation;
- cleanup and shutdown behavior;
- output template name and version.

Example checksums and media paths must never drift into production unchanged. Windows media in particular may expose different WIM image names between editions and channels. Inspect the actual image before setting the unattended answer:

```powershell
dism /Get-WimInfo /WimFile:X:\sources\install.wim
```

Boot commands are also sensitive to firmware, point release, and customized media. Syntax validation proves that HCL parses; it does not prove that a vendor installer will follow the intended boot sequence. Maintain an end-to-end build lane against the exact approved media.

## 3. Treat build credentials as disposable secrets

Image factories need temporary credentials so Packer can finish provisioning. Those credentials are not application credentials and must not survive as shared production secrets.

The repository accepts Packer variables through `PKR_VAR_...` environment variables:

```bash
export PKR_VAR_vsphere_password='...'
export PKR_VAR_ssh_password='temporary-build-password'
export PKR_VAR_ssh_password_hash="$(openssl passwd -6 "$PKR_VAR_ssh_password")"

packer init linux.pkr.hcl
packer build \
  -var-file=profiles/common.pkrvars.hcl \
  -var-file=profiles/ubuntu-24.04.pkrvars.hcl \
  linux.pkr.hcl
```

In a production pipeline, obtain short-lived secrets from a secret manager, mask them in logs, and revoke or rotate them after the build. The finished template should either remove the temporary account or force first-boot credential replacement through an approved bootstrap mechanism.

For vSphere, use a service identity with only the inventory, datastore, network, VM, and template permissions needed by the build or clone job. Separate image-builder and deployment identities so a compromised deployment job cannot replace trusted templates.

## 4. Promote templates by identity

A mutable name such as `ubuntu-24-latest` is convenient for humans but weak as a deployment contract. Record an immutable identity alongside it:

- template UUID or content-library item/version;
- source ISO checksum;
- repository commit;
- Packer version and plugin lock;
- build timestamp;
- validation result;
- vulnerability or policy scan reference;
- promotion status.

A promotion flow can move metadata rather than bytes:

```text
candidate/ubuntu-24.04-20260913.1
  -> integration tests
  -> security approval
  -> approved/ubuntu-24.04-20260913.1
```

Terraform environments should consume the approved version, never an unreviewed candidate or an implicitly changing “latest” target.

## 5. Let Terraform own virtual infrastructure boundaries

The vSphere Terraform path in this repository resolves existing datacenter, cluster, datastore, network, and template objects; clones machines; applies CPU, memory, and disk sizing; and waits for VMware Tools to report guest information.

Authentication is injected at runtime:

```bash
export TF_VAR_vsphere_server='vcenter.example.com'
export TF_VAR_vsphere_user='svc-terraform@vsphere.local'
export TF_VAR_vsphere_password='...'

cd terraform/environments/vsphere
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Keep state in a protected remote backend with locking and version history. Never commit credentials or production `.tfvars` files. Plan output may also contain sensitive values, so access and retention must be controlled.

The current reference path expects DHCP and VMware Tools. That limitation should remain explicit. Static addressing, guest customization, tags, storage policies, datastore clusters, and content-library selection should be added as provider-layer features, not smuggled into a post-provision shell script.

## 6. Generate the configuration-management handoff

After cloning, Terraform writes an Ansible inventory. This is a useful boundary: Terraform owns resources and their discovered connection facts; Ansible owns guest configuration.

A handoff must be deterministic. Its output should state:

- inventory hostname and stable VM identity;
- reachable address;
- operating-system family;
- environment and role groups;
- communicator type and port;
- template version;
- variables needed by the baseline, excluding secrets.

Then the common layer runs:

```bash
cd ansible
ansible-playbook -i inventory.vsphere.generated.ini playbooks/base.yml
ansible-playbook -i inventory.vsphere.generated.ini playbooks/harden.yml
```

Avoid using Terraform provisioners for the full operating-system configuration. Provisioners are difficult to model, retry, and test as an idempotent policy layer. A generated inventory also allows configuration to be rerun without recreating the VM.

## 7. Keep baseline, hardening, and service configuration distinct

These stages answer different questions.

**Baseline** establishes manageability: time synchronization, package sources, logging, required agents, name resolution, and platform accounts.

**Hardening** applies security policy: remote-management restrictions, firewall defaults, audit settings, cryptographic policy, and service minimization.

**Service configuration** turns the general-purpose guest into a database server, CI worker, application node, or other workload.

Separating them reduces coupling. A security baseline can be updated without rebuilding every application role, while a service owner cannot quietly weaken the platform's management and audit settings.

Idempotence is the acceptance criterion. Running a playbook twice against a converged host should produce no unexplained change. Where a reboot is required, represent it explicitly and continue validation after the guest returns.

## 8. Validate each boundary, not only the final machine

A pipeline can be green while delivering an unusable service if its tests cover only syntax. Validation should match the layer:

### Image build

- unattended installation completes from the approved ISO;
- VMware Tools starts;
- temporary media and secrets are removed;
- communicator access works;
- expected OS version and packages are present;
- the template is powered off and versioned.

### Terraform deployment

- plan is reviewed;
- clone uses the approved template identity;
- CPU, memory, disk, network, and placement match input;
- VMware Tools reports a guest address;
- state contains the expected stable identifiers.

### Ansible baseline and hardening

- playbooks converge idempotently;
- SSH or WinRM remains reachable through the approved path;
- time, DNS, repositories, logging, and monitoring work;
- hardening controls are asserted, not merely “executed”;
- reboots do not break management access.

### Service acceptance

- the workload health check passes;
- required dependencies are reachable;
- backup, restore, monitoring, and alert routing are exercised where applicable;
- an owner and decommission path exist.

A syntax-only GitHub Actions job is still valuable, but label it correctly. It validates HCL and answer-file structure; it is not an end-to-end image certification.

## 9. Design rollback at every layer

“Re-run the pipeline” is not a complete rollback plan.

- If a new image fails, point deployment to the prior approved template version.
- If Terraform change fails, use the reviewed prior configuration and state-aware plan; do not manually delete random objects.
- If guest configuration fails, repair with an idempotent playbook or restore a known-good instance according to service state requirements.
- If the service carries data, separate VM rollback from data recovery. Reverting compute while keeping an incompatible database state can make the incident worse.

For stateless fleets, replacement is often safer than in-place reversal. For stateful services, recovery objectives, backup consistency, and application compatibility must drive the procedure.

## 10. Operate the factory as a product

A platform factory needs published support boundaries and measurable service levels even if it has no 24/7 obligation. Useful metrics include:

- image build success rate and duration;
- age of each approved template;
- time from security update to promoted image;
- deployment lead time;
- first-pass Ansible convergence;
- policy exceptions by age and owner;
- percentage of instances on supported template versions.

The service catalogue should tell consumers which OS profiles are supported, which inputs they own, what the platform supplies, how secrets enter the workflow, and what constitutes acceptance.

The repository is intentionally a reference implementation. Its value is the architecture of the handoffs: approved media to immutable image, image to declarative VM, VM facts to idempotent configuration, and configuration to explicit validation. When each handoff is versioned and testable, adding another provider or operating system becomes an extension of the platform rather than another collection of scripts.