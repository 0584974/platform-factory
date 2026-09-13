packer {
  required_version = ">= 1.11.0"

  required_plugins {
    vsphere = {
      source  = "github.com/vmware/vsphere"
      version = ">= 2.5.0, < 3.0.0"
    }
  }
}

variable "vsphere_server" { type = string }
variable "vsphere_username" { type = string }
variable "vsphere_password" {
  type      = string
  sensitive = true
}
variable "insecure_connection" {
  type    = bool
  default = false
}
variable "datacenter" { type = string }
variable "cluster" { type = string }
variable "datastore" { type = string }
variable "network" { type = string }
variable "folder" {
  type    = string
  default = null
}

variable "vm_name" { type = string }
variable "guest_os_type" { type = string }
variable "iso_path" { type = string }
variable "iso_checksum" {
  type    = string
  default = "none"
}
variable "firmware" {
  type    = string
  default = "efi"
}
variable "cpus" {
  type    = number
  default = 2
}
variable "ram_mb" {
  type    = number
  default = 4096
}
variable "disk_size_mb" {
  type    = number
  default = 40960
}

variable "ssh_username" {
  type    = string
  default = "automation"
}
variable "ssh_password" {
  type      = string
  sensitive = true
}
variable "ssh_password_hash" {
  type      = string
  sensitive = true
}

variable "answer_file" { type = string }
variable "answer_file_name" { type = string }
variable "extra_http_content" {
  type    = map(string)
  default = {}
}
variable "boot_command" { type = list(string) }

source "vsphere-iso" "linux" {
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  insecure_connection = var.insecure_connection

  datacenter = var.datacenter
  cluster    = var.cluster
  datastore  = var.datastore
  folder     = var.folder

  vm_name       = var.vm_name
  guest_os_type = var.guest_os_type
  firmware      = var.firmware
  CPUs          = var.cpus
  RAM           = var.ram_mb

  disk_controller_type = ["pvscsi"]

  network_adapters {
    network      = var.network
    network_card = "vmxnet3"
  }

  storage {
    disk_size             = var.disk_size_mb
    disk_thin_provisioned = true
  }

  iso_paths    = [var.iso_path]
  iso_checksum = var.iso_checksum

  http_content = merge(
    var.extra_http_content,
    {
      "${var.answer_file_name}" = templatefile(var.answer_file, {
        username      = var.ssh_username
        password_hash = var.ssh_password_hash
      })
    }
  )

  boot_wait    = "5s"
  boot_command = var.boot_command

  communicator = "ssh"
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "45m"

  shutdown_command    = "sudo shutdown -P now"
  shutdown_timeout    = "15m"
  convert_to_template = true

  configuration_parameters = {
    "disk.EnableUUID" = "TRUE"
  }
}

build {
  sources = ["source.vsphere-iso.linux"]

  provisioner "shell" {
    scripts = [
      "scripts/linux-vmware-tools.sh",
      "scripts/linux-template-cleanup.sh"
    ]
  }
}
