packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_url" { type = string }
variable "iso_checksum" { type = string }
variable "vm_name" { type = string }

source "qemu" "linux" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  output_directory = "output/${var.vm_name}"
  vm_name      = "${var.vm_name}.qcow2"
  disk_size    = "20G"
  format       = "qcow2"
  headless     = true
  ssh_username = "automation"
  ssh_timeout  = "30m"
  shutdown_command = "sudo shutdown -P now"
}

build {
  sources = ["source.qemu.linux"]
  provisioner "shell" {
    inline = [
      "sudo sh -c 'command -v cloud-init >/dev/null || true'",
      "sudo rm -f /etc/ssh/ssh_host_*"
    ]
  }
}
