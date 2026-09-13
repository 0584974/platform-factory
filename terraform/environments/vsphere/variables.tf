variable "allow_unverified_ssl" {
  type        = bool
  description = "Allow an untrusted vCenter TLS certificate. Keep false in production."
  default     = false
}

variable "datacenter" { type = string }
variable "cluster" { type = string }
variable "datastore" { type = string }
variable "network" { type = string }

variable "vm_folder" {
  type        = string
  description = "Existing vSphere VM folder. Null deploys to the default VM folder."
  default     = null
}

variable "machines" {
  description = "VMs cloned from existing vSphere templates. Templates should include VMware Tools and SSH/WinRM bootstrap."
  type = map(object({
    os_family    = string
    template     = string
    num_cpus     = number
    memory_mb    = number
    disk_size_gb = number
  }))

  validation {
    condition     = alltrue([for machine in values(var.machines) : contains(["linux", "windows"], machine.os_family)])
    error_message = "machines[*].os_family must be linux or windows."
  }
}
