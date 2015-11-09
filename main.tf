#
# Variables
#

# AWS access keys
variable "aws_access_key" {}
variable "aws_secret_key" {}

# SSH keys to access instances
variable "ssh_key" {}
variable "ssh_key_name" {}

# Base Image
variable "base_image_ami" {}

# Instance Type
variable "instance_type" {}
variable "vpc_id" {}
variable "subnet_id" {}


#
# Template
#

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "us-east-1"
}

resource "aws_security_group" "owncloud_sg" {
  name = "owncloud-server"
  description = "Open inbound 443 and SSH for ownCloud server access"
  vpc_id = "${var.vpc_id}"
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ownCloud-server" {
  ami = "${var.base_image_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.owncloud_sg.id}"]
  key_name = "${var.ssh_key_name}"
  tags {
    Name = "ownCloud-server"
  }

  provisioner "file" {
    source = "./ops/files_to_provision/"
    destination = "/tmp"
    connection {
      host = "${self.public_ip}"
      user = "centos"
      key_file = "${var.ssh_key}"
    }
  }

  provisioner "remote-exec" {
    scripts = [ "./ops/scripts/configure_node.sh" ]
    connection {
      host = "${self.public_ip}"
      user = "centos"
      key_file = "${var.ssh_key}"
    }
  }

}

