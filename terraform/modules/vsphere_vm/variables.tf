variable "name" { type = string }
variable "resource_pool_id" { type = string }
variable "datastore_id" { type = string }
variable "network_id" { type = string }
variable "template_uuid" { type = string }
variable "guest_id" { type = string }
variable "scsi_type" { type = string }
variable "folder" {
  type    = string
  default = null
}
variable "num_cpus" {
  type    = number
  default = 2
}
variable "memory_mb" {
  type    = number
  default = 4096
}
variable "disk_size_gb" {
  type    = number
  default = 40
}
variable "adapter_type" {
  type    = string
  default = "vmxnet3"
}
variable "thin_provisioned" {
  type    = bool
  default = true
}
variable "wait_for_guest_ip_timeout" {
  type    = number
  default = 10
}
