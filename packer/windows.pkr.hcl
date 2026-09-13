# Skeleton for customer-provided/licensed Windows media.
# No Microsoft ISO or product key is stored in this repository.
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

source "qemu" "windows" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  output_directory = "output/${var.vm_name}"
  vm_name      = "${var.vm_name}.qcow2"
  disk_size    = "64G"
  format       = "qcow2"
  headless     = true
  communicator = "winrm"
  winrm_username = "Administrator"
  winrm_timeout = "2h"
}

build {
  sources = ["source.qemu.windows"]
}
