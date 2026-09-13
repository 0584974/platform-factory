output "id" {
  value = vsphere_virtual_machine.this.id
}

output "default_ip_address" {
  value = vsphere_virtual_machine.this.default_ip_address
}

output "guest_ip_addresses" {
  value = vsphere_virtual_machine.this.guest_ip_addresses
}
