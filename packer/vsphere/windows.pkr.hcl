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
variable "vmtools_iso_path" {
  type        = string
  description = "Optional datastore path to a VMware Tools Windows ISO. Leave empty only if the install media already provides Tools."
  default     = ""
}
variable "iso_checksum" {
  type    = string
  default = "none"
}
variable "image_name" { type = string }
variable "firmware" {
  type    = string
  default = "efi-secure"
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
  default = 61440
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}
variable "winrm_password" {
  type      = string
  sensitive = true
}

source "vsphere-iso" "windows" {
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

  iso_paths    = compact([var.iso_path, var.vmtools_iso_path])
  iso_checksum = var.iso_checksum

  cd_content = {
    "Autounattend.xml" = templatefile("windows/Autounattend.xml.pkrtpl.hcl", {
      image_name     = var.image_name
      admin_password = var.winrm_password
      admin_username = var.winrm_username
    })
    "SetupComplete.ps1" = file("windows/SetupComplete.ps1")
  }
  cd_label = "PACKER"

  boot_wait    = "3s"
  boot_command = ["<spacebar>"]

  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "2h"
  winrm_use_ntlm = true

  shutdown_command    = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer shutdown\""
  shutdown_timeout    = "30m"
  convert_to_template = true

  configuration_parameters = {
    "disk.EnableUUID" = "TRUE"
  }
}

build {
  sources = ["source.vsphere-iso.windows"]

  provisioner "powershell" {
    scripts = ["windows/Finalize-Template.ps1"]
  }
}
