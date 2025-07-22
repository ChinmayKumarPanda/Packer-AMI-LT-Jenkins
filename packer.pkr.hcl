packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

# --------------------
# Variables
# --------------------
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "ami_name_prefix" {
  type    = string
  default = "al2023-node-app"
}

# --------------------
# Amazon Linux 2023 Source
# --------------------
source "amazon-ebs" "al2023-node" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  ssh_username  = "ec2-user"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-kernel-6.1-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"] # Amazon official
    most_recent = true
  }

  tags = {
    Name        = "AL2023 Node App AMI"
    Environment = "dev"
    BuiltBy     = "Packer"
  }

  snapshot_tags = {
    Name        = "AL2023 Node App Snapshot"
    Environment = "dev"
    BuiltBy     = "Packer"
  }
}

# --------------------
# Build Block
# --------------------
build {
  name    = "build-node-app-ami"
  sources = ["source.amazon-ebs.al2023-node"]

  provisioner "file" {
    source      = "app"
    destination = "/tmp/node-app"
  }

  provisioner "file" {
    source      = "scripts/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh"
    ]
  }
}

