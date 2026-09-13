terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8"
    }
  }
}

resource "libvirt_volume" "os" {
  name   = "${var.name}.qcow2"
  pool   = "default"
  source = var.base_image
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "seed" {
  count = var.os_family == "linux" ? 1 : 0
  name  = "${var.name}-cloudinit.iso"
  pool  = "default"
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname       = var.name
    ssh_public_key = var.ssh_public_key
  })
}

resource "libvirt_domain" "vm" {
  name   = var.name
  memory = var.memory_mb
  vcpu   = var.vcpu

  disk {
    volume_id = libvirt_volume.os.id
  }

  dynamic "cloudinit" {
    for_each = var.os_family == "linux" ? [1] : []
    content {
      disk_id = libvirt_cloudinit_disk.seed[0].id
    }
  }

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }
}
