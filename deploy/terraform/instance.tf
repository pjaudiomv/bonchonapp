resource "aws_instance" "bonchon" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = data.aws_subnets.subnets.ids[0]
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.bonchon.key_name
  vpc_security_group_ids = [aws_security_group.bonchon.id]
  iam_instance_profile   = aws_iam_instance_profile.bonchon.name

  user_data = data.cloudinit_config.root_server.rendered

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 30
    volume_type           = "gp3"
  }

  tags = {
    Name = "bonchon"
  }

  volume_tags = {
    Name = "bonchon"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_key_pair" "bonchon" {
  key_name   = "bonchon-${terraform.workspace}"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "bonchon" {
  domain = "vpc"
}

resource "aws_eip_association" "bonchon" {
  instance_id   = aws_instance.bonchon.id
  allocation_id = aws_eip.bonchon.id
}

resource "aws_security_group" "bonchon" {
  vpc_id = data.aws_vpc.default.id
  name   = "bonchon-${terraform.workspace}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  owners = ["099720109477"]

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  apache_conf = base64encode(templatefile("${path.root}/templates/apache.conf.tpl", { domain = "locator.bonchon.app" }))
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
write_files:
  - encoding: b64
    content: "${local.apache_conf}"
    path: /etc/apache2/sites-available/locator.bonchon.app.conf
    permissions: '0644'
packages:
  - apt-transport-https
  - ca-certificates
  - apache2
  - php
  - php-curl
  - php-dom
  - php-mbstring
  - php-mysql
  - php-gd
  - php-xml
  - php-zip
  - mysql-client
  - mysql-server
  - libapache2-mod-php
  - unzip
  - certbot
  - python3-certbot-apache
  - python3-pip
  - jq
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<BOF
#!/bin/bash
# configure apache
mkdir /var/www/locator.bonchon.app
chown -R $USER:$USER /var/www/locator.bonchon.app
chmod -R 755 /var/www/locator.bonchon.app
sed -i 's/^\tOptions Indexes FollowSymLinks/\tOptions FollowSymLinks/' /etc/apache2/apache2.conf
a2ensite locator.bonchon.app.conf
a2dissite 000-default.conf
a2enmod rewrite
systemctl restart apache2
# configure mysql
systemctl start mysql.service
# secure
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
mysql_secure_installation --password=password --use-default
mysql --user=root --password=password --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;"
mysql --execute="UNINSTALL COMPONENT 'file://component_validate_password';"
# bonchon db
mysql --execute="CREATE DATABASE bonchon;"
mysql --execute="CREATE USER 'locator'@'localhost' IDENTIFIED WITH mysql_native_password BY 'locator';"
mysql --execute="GRANT ALL PRIVILEGES ON bonchon.* TO 'locator'@'localhost';"
# flush
mysql --execute="FLUSH PRIVILEGES;"

# Do the yap and BMLT Things
wget https://github.com/bmlt-enabled/bmlt-root-server/releases/download/2.16.4/bmlt-root-server.zip
wget https://github.com/bmlt-enabled/yap/releases/download/4.1.0-beta1/yap-4.1.0-beta1.zip
unzip bmlt-root-server.zip
unzip yap-4.1.0-beta1.zip
rm -f bmlt-root-server.zip
rm -f yap-4.1.0-beta1.zip
mv main_server /var/www/locator.bonchon.app/main_server
mv  yap-4.1.0-beta1 /var/www/locator.bonchon.app/yap
#rm -f /var/www/locator.bonchon.app/index.html
chown -R www-data: /var/www/locator.bonchon.app

sudo systemctl is-enabled apache2.service
sudo systemctl is-enabled mysql.service


# Need to run after boot
# sudo certbot --apache
BOF
  }
}

data "aws_iam_policy_document" "bonchon_ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bonchon" {
  name               = "bonchon-ec2-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.bonchon_ec2_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "bonchon_ssm" {
  role       = aws_iam_role.bonchon.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bonchon" {
  name = "bonchon-${terraform.workspace}"
  role = aws_iam_role.bonchon.name
}
