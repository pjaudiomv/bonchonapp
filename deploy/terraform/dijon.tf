resource "oci_core_instance" "root_server" {
  availability_domain = oci_core_subnet.free.availability_domain
  compartment_id      = data.oci_identity_compartment.default.id
  display_name        = "dijon-${terraform.workspace}"
  shape               = "VM.Standard.A1.Flex"

  create_vnic_details {
    assign_public_ip = true
    display_name     = "eth01"
    hostname_label   = "dijon"
    nsg_ids          = [oci_core_network_security_group.bonchon.id]
    subnet_id        = oci_core_subnet.free.id
  }

  metadata = {
    ssh_authorized_keys = <<EOT
%{for key, val in var.ssh_public_keys~}
${val}
%{endfor~}
EOT
    user_data           = data.cloudinit_config.root_server.rendered
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_jammy_arm.images.0.id
    boot_volume_size_in_gbs = 50
  }

  shape_config {
    ocpus         = 2
    memory_in_gbs = 4
  }

  lifecycle {
    ignore_changes = [source_details]
  }
}


data "cloudinit_config" "root_server" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - mysql-client
  - mysql-server
  - unzip
  - jq
  - curl
  - wget
  - docker.io
  - docker-compose
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<BOF
#!/bin/bash
pip3 install oci-cli
# disable firewall
ufw disable
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F


# configure mysql
systemctl start mysql.service
# secure
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
mysql_secure_installation --password=password --use-default
mysql --user=root --password=password --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;"
mysql --execute="UNINSTALL COMPONENT 'file://component_validate_password';"
# root server db
mysql --execute="CREATE DATABASE bmlt;"
mysql --execute="CREATE USER '${var.root_server_mysql_username}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.root_server_mysql_password}';"
mysql --execute="GRANT ALL PRIVILEGES ON bmlt.* TO '${var.root_server_mysql_username}'@'localhost';"
BOF
  }
}

variable "domain" {
  type        = string
  description = "Website domain"
  default     = "dijon.aws.bmlt.app"
}

variable "root_server_mysql_username" {
  type        = string
  description = "Root server mysql username"
  default     = "bmlt"
}

variable "root_server_mysql_password" {
  type        = string
  description = "Root server mysql password"
  default     = "bmlt"
}

locals {
  apache_conf = base64encode(templatefile("${path.root}/templates/apache.conf.tpl", { domain = var.domain }))
}


output "dijon_public_ip" {
  value = oci_core_instance.root_server.public_ip
}

