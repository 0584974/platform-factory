resource "libvirt_network" "platform" {
  name      = "platform-factory"
  mode      = "nat"
  domain    = "platform.local"
  addresses = ["10.77.0.0/24"]
}

module "vm" {
  for_each       = var.machines
  source         = "../../modules/vm"
  name           = each.key
  os_family      = each.value.os_family
  memory_mb      = each.value.memory_mb
  vcpu           = each.value.vcpu
  base_image     = each.value.base_image
  network_name   = libvirt_network.platform.name
  ssh_public_key = var.ssh_public_key
}

locals {
  inventory = join("\n", concat(
    ["[linux]"],
    [for k, v in module.vm : "${k} ansible_host=${try(v.ip_addresses[0], "")} ansible_user=automation" if var.machines[k].os_family == "linux"],
    ["", "[windows]"],
    [for k, v in module.vm : "${k} ansible_host=${try(v.ip_addresses[0], "")} ansible_connection=winrm" if var.machines[k].os_family == "windows"]
  ))
}

resource "local_file" "inventory" {
  filename = "${path.module}/../../../ansible/inventory.generated.ini"
  content  = local.inventory
}
