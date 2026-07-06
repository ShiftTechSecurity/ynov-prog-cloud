output "instances" {
  value = {
    for tier, instance in aws_instance.tiers :
    tier => {
      id         = instance.id
      arn        = instance.arn
      private_ip = instance.private_ip
      public_ip  = instance.public_ip
    }
  }
}

output "instance_ids" {
  value = {
    for tier, instance in aws_instance.tiers :
    tier => instance.id
  }
}

output "instance_arns" {
  value = {
    for tier, instance in aws_instance.tiers :
    tier => instance.arn
  }
}

output "encrypted_data_volumes" {
  value = {
    for tier, volume in aws_ebs_volume.sensitive_data :
    tier => {
      id         = volume.id
      size       = volume.size
      type       = volume.type
      encrypted  = volume.encrypted
      kms_key_id = volume.kms_key_id
    }
  }
}
