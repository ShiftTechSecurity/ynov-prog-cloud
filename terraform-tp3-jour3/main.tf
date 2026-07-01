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
    Name        = "${local.resource_name_prefix}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.resource_name_prefix}-public-subnet"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.resource_name_prefix}-private-subnet"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.resource_name_prefix}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${local.resource_name_prefix}-public-rt"
    Environment = var.environment
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

  name        = "${local.resource_name_prefix}-sg-${each.key}"
  description = "SG ${each.key}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${local.resource_name_prefix}-sg-${each.key}"
    Environment = var.environment
    Role        = each.value.role
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
    echo "${var.environment}-${each.key}-${var.prenom}" > /tmp/tier.txt
  EOF

  tags = {
    Name        = "${local.resource_name_prefix}-${each.key}"
    Environment = var.environment
    Role        = each.value.role
  }
}

###############################################################################################################################################################
# MONITORING
###############################################################################################################################################################

resource "aws_sns_topic" "alerts" {
  name = "${local.resource_name_prefix}-alerts"

  tags = {
    Name        = "${local.resource_name_prefix}-alerts"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = aws_instance.servers

  alarm_name          = "${local.resource_name_prefix}-${each.key}-cpu-high"
  alarm_description   = "CPU utilization is above 70 percent for ${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${local.resource_name_prefix}-${each.key}-cpu-high"
    Environment = var.environment
    Role        = var.tiers[each.key].role
  }
}
