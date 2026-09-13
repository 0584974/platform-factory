variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "machines" {
  type = map(object({
    os_family  = string
    memory_mb  = number
    vcpu       = number
    base_image = string
  }))
}
