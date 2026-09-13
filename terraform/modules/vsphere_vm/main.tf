resource "vsphere_virtual_machine" "this" {
  name             = var.name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder

  num_cpus  = var.num_cpus
  memory    = var.memory_mb
  guest_id  = var.guest_id
  scsi_type = var.scsi_type

  wait_for_guest_ip_timeout  = var.wait_for_guest_ip_timeout
  wait_for_guest_net_timeout = var.wait_for_guest_ip_timeout

  network_interface {
    network_id   = var.network_id
    adapter_type = var.adapter_type
  }

  disk {
    label            = "disk0"
    size             = var.disk_size_gb
    thin_provisioned = var.thin_provisioned
  }

  clone {
    template_uuid = var.template_uuid
  }
}
