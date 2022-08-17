output "public_ip" {
  value = oci_core_public_ip.this.ip_address
}
