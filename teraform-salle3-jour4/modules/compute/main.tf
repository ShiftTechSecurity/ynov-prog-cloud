// AMI officielle Amazon Linux 2023 recuperee dynamiquement.
// Cela evite de figer un identifiant AMI qui deviendrait obsolete selon la region.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

// Instances des trois tiers.
// Les choix d'exposition, de subnet et de Security Group sont portes par tier_config.
resource "aws_instance" "tiers" {
  for_each = var.tier_config

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = each.value.subnet_id
  private_ip                  = each.value.private_ip
  vpc_security_group_ids      = [each.value.security_group_id]
  associate_public_ip_address = each.value.associate_public_ip
  iam_instance_profile        = var.instance_profile_name
  user_data                   = each.value.user_data
  user_data_replace_on_change = true

  metadata_options {
    # IMDSv2 obligatoire pour reduire le risque de vol de metadata depuis l'instance.
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    # Chiffrement systematique du disque racine, y compris pour le tier presentation.
    volume_size = 12
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}"
    Tier = each.key
    Role = each.value.role
  })
}

// Volumes de donnees chiffres pour les tiers sensibles.
// Le web n'en recoit pas dans la v1 afin de minimiser le stockage et le cout.
resource "aws_ebs_volume" "sensitive_data" {
  for_each = {
    for tier, config in var.tier_config : tier => config
    if config.data_volume_size > 0
  }

  availability_zone = aws_instance.tiers[each.key].availability_zone
  size              = each.value.data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-data"
    Tier = each.key
    Role = each.value.role
  })
}

// Attachement des volumes chiffres aux instances app/db.
resource "aws_volume_attachment" "sensitive_data" {
  for_each = aws_ebs_volume.sensitive_data

  device_name = "/dev/sdf"
  volume_id   = each.value.id
  instance_id = aws_instance.tiers[each.key].id
}
