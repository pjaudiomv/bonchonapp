output "bonchon_aws" {
  value = {
    eip      = aws_eip.bonchon.public_ip
    instance = aws_instance.bonchon.id
  }
}
