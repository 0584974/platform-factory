variable "name" { type = string }
variable "memory_mb" { type = number }
variable "vcpu" { type = number }
variable "base_image" { type = string }
variable "network_name" { type = string }

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "os_family" {
  type = string

  validation {
    condition     = contains(["linux", "windows"], var.os_family)
    error_message = "os_family must be linux or windows"
  }
}
