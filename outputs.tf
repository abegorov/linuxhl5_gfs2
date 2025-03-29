output "private_ips" {
  description = "Private IPs of the instances."
  value = {
    for h in concat(
      yandex_compute_instance.iscsi,
      yandex_compute_instance.gfs
    ) : h.hostname => h.network_interface.0.ip_address
  }
}
output "public_ips" {
  description = "Public IPs of the instances."
  value = {
    for h in concat(
      yandex_compute_instance.iscsi,
      yandex_compute_instance.gfs
    ) : h.hostname => h.network_interface.0.nat_ip_address
  }
}
