locals {
  # Prefixe stable et lisible pour relier les ressources au projet, a l'environnement
  # et a l'environnement. Le suffixe technique est separe du nom d'equipe pour
  # eviter de remplacer des ressources AWS immuables lors d'un simple renommage.
  resource_name_prefix = lower(replace("${var.name_prefix}-${var.environment}-${var.resource_suffix}", "_", "-"))

  # Tags communs obligatoires pour la tracabilite, le FinOps et l'audit.
  # Ils repondent directement aux corrections de la Salle 1 sur les ressources non taguees.
  common_tags = {
    Project     = "NordCloud"
    Course      = "prog-cloud"
    Exercise    = "salle3-jour4"
    Environment = var.environment
    Owner       = var.project_owner
    Team        = var.prenom
    ManagedBy   = "terraform"
  }

  # IPs privees stables pour permettre au web de cibler l'API et a l'API de cibler PostgreSQL
  # sans devoir attendre des outputs d'instances deja creees.
  web_private_ip = cidrhost(var.public_subnet_cidr, 10)
  app_private_ip = cidrhost(var.app_subnet_cidr, 10)
  db_private_ip  = cidrhost(var.data_subnet_cidr, 10)

  # Definition logique des trois tiers. Cette map centralise le role, le subnet,
  # le Security Group et le comportement d'exposition de chaque couche.
  tier_config = {
    web = {
      # Tier presentation : seule couche exposee a Internet.
      role                = "presentation"
      subnet_id           = module.network.public_subnet_id
      security_group_id   = module.security.web_security_group_id
      private_ip          = local.web_private_ip
      associate_public_ip = true
      data_volume_size    = 0
      user_data = templatefile("${path.module}/user_data/web.sh", {
        project_name   = "NordCloud"
        environment    = var.environment
        app_private_ip = local.app_private_ip
        app_port       = var.app_port
      })
    }

    app = {
      # Tier application : pas d'IP publique, accessible uniquement depuis le web.
      role                = "application"
      subnet_id           = module.network.app_subnet_id
      security_group_id   = module.security.app_security_group_id
      private_ip          = local.app_private_ip
      associate_public_ip = false
      data_volume_size    = var.encrypted_data_volume_size_gb
      user_data = templatefile("${path.module}/user_data/app.sh", {
        project_name        = "NordCloud"
        environment         = var.environment
        app_port            = var.app_port
        db_private_ip       = local.db_private_ip
        db_port             = var.db_port
        db_app_password_b64 = base64encode(var.db_app_password)
      })
    }

    db = {
      # Tier donnees : isole du public et accessible uniquement depuis l'application.
      role                = "data"
      subnet_id           = module.network.data_subnet_id
      security_group_id   = module.security.db_security_group_id
      private_ip          = local.db_private_ip
      associate_public_ip = false
      data_volume_size    = var.encrypted_data_volume_size_gb
      user_data = templatefile("${path.module}/user_data/db.sh", {
        project_name        = "NordCloud"
        environment         = var.environment
        app_private_ip      = local.app_private_ip
        db_port             = var.db_port
        db_app_password_b64 = base64encode(var.db_app_password)
      })
    }
  }
}
