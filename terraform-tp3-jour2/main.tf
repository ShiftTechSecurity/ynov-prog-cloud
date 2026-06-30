###############################################################################################################################################################
#####                                                                                                                                                     #####
#####    ███████╗██╗  ██╗██╗███████╗████████╗     ████████╗███████╗ ██████╗██╗  ██╗     ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██    ██║    #####
#####    ██╔════╝██║  ██║██║██╔════╝╚══██╔══╝     ╚══██╔══╝██╔════╝██╔════╝██║  ██║     ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝ ██  ██╔╝    #####
#####    ███████╗███████║██║██████╗    ██║           ██║   █████╗  ██║     ███████║     ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║     ████╔╝     #####
#####    ╚════██║██╔══██║██║██╔═══╝    ██║           ██║   ███╗    ██║     ██║  ██║     ╚════██║███╗    ██║     ██║   ██║██╔═██╗ ██║   ██║      ██╔╝      #####
#####    ███████║██║  ██║██║██║        ██║           ██║   ███████╗╚██████╗██║  ██║     ███████║███████╗╚██████╗╚██████╔╝██║  ██╗██║   ██║      ██║       #####
#####    ╚══════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝           ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝       #####
#####                                                                                                                                                     #####
###############################################################################################################################################################
# Authors: Tristan Truckle
# Version: 1.0
# Date: 30-06-2026
# Subject: Architecture 3-tiers AWS
# Description:
# Notes :
###############################################################################################################################################################

###############################################################################################################################################################
# NETWORKING
###############################################################################################################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################################################################################################################################################
# SECURITY GROUPS
###############################################################################################################################################################

resource "aws_security_group" "tiers" {
  for_each = var.tiers

  name        = "${var.name_prefix}-${var.prenom}-sg-${each.key}"
  description = "SG ${each.key}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-sg-${each.key}"
    Role = each.value.role
  }
}

resource "aws_security_group_rule" "egress" {
  for_each = var.tiers

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tiers[each.key].id
}

resource "aws_security_group_rule" "web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tiers["web"].id
}

resource "aws_security_group_rule" "web_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tiers["web"].id
}

resource "aws_security_group_rule" "web_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip]
  security_group_id = aws_security_group.tiers["web"].id
}

resource "aws_security_group_rule" "api_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tiers["web"].id
  security_group_id        = aws_security_group.tiers["api"].id
}

resource "aws_security_group_rule" "db_from_api" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tiers["api"].id
  security_group_id        = aws_security_group.tiers["db"].id
}

###############################################################################################################################################################
# EC2
###############################################################################################################################################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "servers" {
  for_each = var.tiers

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = each.value.subnet == "public" ? aws_subnet.public.id : aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.tiers[each.key].id]
  associate_public_ip_address = each.value.public_ip
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    echo "${each.key}-${var.prenom}" > /tmp/tier.txt
  EOF

  tags = {
    Name = "${var.name_prefix}-${var.prenom}-${each.key}"
    Role = each.value.role
  }
}
