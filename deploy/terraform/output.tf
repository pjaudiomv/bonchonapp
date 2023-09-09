output "public_ip" {
  value = oci_core_public_ip.this.ip_address
}

output "bonchon_aws" {
  value = {
    eip      = aws_eip.bonchon.public_ip
    instance = aws_instance.bonchon.id
  }
}
