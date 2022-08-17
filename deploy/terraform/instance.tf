resource "oci_core_instance" "bonchon" {
  availability_domain = oci_core_subnet.free.availability_domain
  compartment_id      = data.oci_identity_compartment.default.id
  display_name        = "bonchon-${terraform.workspace}"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    assign_public_ip = false
    display_name     = "eth01"
    hostname_label   = "bonchon"
    nsg_ids          = [oci_core_network_security_group.bonchon.id]
    subnet_id        = oci_core_subnet.free.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.cloudinit_config.bonchon.rendered
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_jammy.images.0.id
  }
}

resource "oci_core_public_ip" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "bonchon-${terraform.workspace}"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.this.private_ips[0]["id"]
}

data "oci_core_vnic_attachments" "this" {
  compartment_id      = data.oci_identity_compartment.default.id
  availability_domain = local.availability_domain
  instance_id         = oci_core_instance.bonchon.id
}

data "oci_core_vnic" "this" {
  vnic_id = data.oci_core_vnic_attachments.this.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "this" {
  vnic_id = data.oci_core_vnic.this.id
}

data "oci_identity_compartment" "default" {
  id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "this" {
  compartment_id = data.oci_identity_compartment.default.id
}

resource "oci_core_vcn" "free" {
  dns_label      = "free"
  cidr_block     = var.vpc_cidr_block
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "free-${terraform.workspace}"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.free.id
  display_name   = "free-${terraform.workspace}"
  enabled        = "true"
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.free.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_network_security_group" "bonchon" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.free.id
  display_name   = "dijon-nsg"
  freeform_tags  = { "Service" = "dijon" }
}

resource "oci_core_network_security_group_security_rule" "bonchon_egress_rule" {
  network_security_group_id = oci_core_network_security_group.bonchon.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Egress All"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "bonchon_ingress_ssh_rule" {
  network_security_group_id = oci_core_network_security_group.bonchon.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "ssh-ingress"
  source                    = local.myip
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "bonchon_ingress_443_rule" {
  network_security_group_id = oci_core_network_security_group.bonchon.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "443-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "bonchon_ingress_80_rule" {
  network_security_group_id = oci_core_network_security_group.bonchon.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "80-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_core_security_list" "this" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.free.id
  display_name   = "free-${terraform.workspace}"

}

resource "oci_core_subnet" "free" {
  availability_domain        = local.availability_domain
  cidr_block                 = cidrsubnet(var.vpc_cidr_block, 8, 0)
  display_name               = "free-${terraform.workspace}"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "free"
  compartment_id             = data.oci_identity_compartment.default.id
  vcn_id                     = oci_core_vcn.free.id
  route_table_id             = oci_core_default_route_table.this.id
  security_list_ids          = [oci_core_security_list.this.id]
  dhcp_options_id            = oci_core_vcn.free.default_dhcp_options_id
}

data "oci_core_images" "ubuntu_jammy" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_images" "ubuntu_jammy_arm" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "cloudinit_config" "bonchon" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config

package_update: true
package_upgrade: true
packages:
  - apache2
  - mysql-server
  - mysql-client
  - php
  - php-mysql
  - php-curl
  - php-gd
  - php-zip
  - php-mbstring
  - php-xml
  - libapache2-mod-php
  - software-properties-common
  - unzip
  - htop
  - python3-pip
  - certbot
  - python3-certbot-apache
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<BOF
#!/bin/bash
ufw disable
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# Do the yap and BMLT Things
wget https://github.com/bmlt-enabled/bmlt-root-server/releases/download/2.16.4/bmlt-root-server.zip
wget https://github.com/bmlt-enabled/yap/releases/download/4.1.0-beta1/yap-4.1.0-beta1.zip
unzip bmlt-root-server.zip
unzip yap-4.1.0-beta1.zip
rm -f bmlt-root-server.zip
rm -f yap-4.1.0-beta1.zip
mv main_server /var/www/html/main_server
mv  yap-4.1.0-beta1 /var/www/html/yap
#rm -f /var/www/html/index.html
chown -R www-data: /var/www/html
# start service and makes sure they stay that way on re-boot
service apache2 start
service mysql start
sudo systemctl is-enabled apache2.service
sudo systemctl is-enabled mysql.service
# configure rewrite
#sed -i '/^\s*DocumentRoot \/var\/www\/html.*/a <Directory "\/var\/www\/html">\nAllowOverride All\n<\/Directory>' /etc/apache2/sites-available/000-default.conf
a2enmod rewrite expires
service apache2 restart
BOF
  }
}

data "http" "ip" {
  url = "https://ifconfig.me/all.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  myip                = "${jsondecode(data.http.ip.body).ip_addr}/32"
  availability_domain = [for i in data.oci_identity_availability_domains.this.availability_domains : i if length(regexall("US-ASHBURN-AD-3", i.name)) > 0][0].name
}
