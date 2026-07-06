output "architecture" {
  description = "3-tier architecture summary."
  value = {
    # Sortie orientee audit : role, IPs, SG et volume chiffre par tier.
    for tier, instance in module.compute.instances :
    tier => {
      role             = local.tier_config[tier].role
      instance_id      = instance.id
      private_ip       = instance.private_ip
      public_ip        = instance.public_ip
      security_group   = module.security.security_group_names[tier]
      encrypted_volume = lookup(module.compute.encrypted_data_volumes, tier, null)
    }
  }
}

output "architecture_flows" {
  description = "Allowed network flows."
  value = {
    # Recapitulatif lisible des flux a reporter dans le schema d'architecture.
    internet_to_web  = "TCP 80/443 from 0.0.0.0/0"
    admin_to_web     = "TCP 22 from ${var.admin_cidr}"
    web_to_app       = "TCP ${var.app_port} from SG web to SG app"
    app_to_db        = "TCP ${var.db_port} from SG app to SG db"
    bootstrap_egress = var.enable_private_nat ? "HTTP/HTTPS/DNS egress for package installation through NAT" : "Disabled; use a prepared AMI or another bootstrap strategy"
    direct_web_to_db = "Denied"
    internet_to_db   = "Denied"
  }
}

output "web_url" {
  description = "Presentation tier URL."
  # Le seul endpoint public attendu dans cette v1.
  value = "http://${module.compute.instances.web.public_ip}"
}

output "kms_key_arn" {
  description = "KMS key used for sensitive encrypted volumes."
  value       = aws_kms_key.sensitive_data.arn
}

output "iam_instance_profile" {
  description = "Least-privilege EC2 instance profile name."
  value       = module.iam.ec2_instance_profile_name
}

output "nonprod_schedule_enabled" {
  description = "Whether non-production stop/start schedules were created."
  value       = module.scheduler.schedule_enabled
}
