data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  for_each      = var.machines
  name          = each.value.template
  datacenter_id = data.vsphere_datacenter.dc.id
}

module "vm" {
  for_each = var.machines
  source   = "../../modules/vsphere_vm"

  name             = each.key
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  network_id       = data.vsphere_network.network.id
  template_uuid    = data.vsphere_virtual_machine.template[each.key].id
  guest_id         = data.vsphere_virtual_machine.template[each.key].guest_id
  scsi_type        = data.vsphere_virtual_machine.template[each.key].scsi_type
  folder           = var.vm_folder

  num_cpus     = each.value.num_cpus
  memory_mb    = each.value.memory_mb
  disk_size_gb = each.value.disk_size_gb
}

locals {
  inventory = join("\n", concat(
    ["[linux]"],
    [for name, vm in module.vm : "${name} ansible_host=${vm.default_ip_address} ansible_user=automation" if var.machines[name].os_family == "linux"],
    ["", "[windows]"],
    [for name, vm in module.vm : "${name} ansible_host=${vm.default_ip_address} ansible_user=Administrator ansible_connection=winrm ansible_winrm_transport=ntlm ansible_winrm_server_cert_validation=ignore" if var.machines[name].os_family == "windows"]
  ))
}

resource "local_file" "inventory" {
  filename = "${path.module}/../../../ansible/inventory.vsphere.generated.ini"
  content  = local.inventory
}

output "virtual_machines" {
  value = {
    for name, vm in module.vm : name => {
      id = vm.id
      ip = vm.default_ip_address
    }
  }
}
