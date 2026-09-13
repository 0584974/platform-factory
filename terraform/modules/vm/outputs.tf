output "name" { value = libvirt_domain.vm.name }
output "ip_addresses" { value = libvirt_domain.vm.network_interface[0].addresses }
