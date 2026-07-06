// Module reseau : construit le socle de segmentation 3-tiers.
// Le subnet web est public ; les subnets app et data restent prives pour reduire
// la surface d'attaque et appliquer le principe de cloisonnement.
module "network" {
  source = "./modules/network"

  name_prefix        = local.resource_name_prefix
  availability_zone  = var.availability_zone
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  app_subnet_cidr    = var.app_subnet_cidr
  data_subnet_cidr   = var.data_subnet_cidr
  enable_private_nat = var.enable_private_nat
  tags               = local.common_tags
}

// Module securite : applique les flux autorises par couche.
// Internet ne peut joindre que le tier presentation, le web parle a l'app,
// et l'app seule parle a la base de donnees.
module "security" {
  source = "./modules/security"

  name_prefix = local.resource_name_prefix
  vpc_id      = module.network.vpc_id
  vpc_cidr    = var.vpc_cidr
  admin_cidr  = var.admin_cidr
  app_port    = var.app_port
  db_port     = var.db_port
  tags        = local.common_tags
}

// Cle KMS dediee aux donnees sensibles de la mission.
// Elle chiffre les volumes racine EC2 et les volumes EBS attaches aux tiers app/db.
resource "aws_kms_key" "sensitive_data" {
  description             = "NordCloud Salle 3 key for sensitive EC2 and EBS volumes"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_name_prefix}-sensitive-data-kms"
  })
}

// Alias lisible pour faciliter l'audit dans la console AWS.
resource "aws_kms_alias" "sensitive_data" {
  name          = "alias/${local.resource_name_prefix}-sensitive-data"
  target_key_id = aws_kms_key.sensitive_data.key_id
}

// IAM minimal pour les instances : aucun privilege admin global.
// La politique autorise seulement l'envoi de metriques custom dans le namespace du TP.
module "iam" {
  source = "./modules/iam"

  name_prefix      = local.resource_name_prefix
  metric_namespace = "NordCloud/Salle3"
  tags             = local.common_tags
}

// Compute : cree les trois instances EC2 et chiffre les volumes.
// Les caracteristiques reseau viennent de local.tier_config pour garder le modele lisible.
module "compute" {
  source = "./modules/compute"

  name_prefix           = local.resource_name_prefix
  instance_type         = var.instance_type
  kms_key_arn           = aws_kms_key.sensitive_data.arn
  instance_profile_name = module.iam.ec2_instance_profile_name
  tier_config           = local.tier_config
  tags                  = local.common_tags
}

// Option FinOps : extinction/demarrage programme des environnements non-prod.
// Desactive par defaut pour ne pas perturber l'evaluation, activable via variable.
module "scheduler" {
  source = "./modules/scheduler"

  enable_schedule           = var.enable_nonprod_schedule && var.environment != "prod"
  name_prefix               = local.resource_name_prefix
  instance_ids              = module.compute.instance_ids
  instance_arns             = module.compute.instance_arns
  stop_schedule_expression  = var.stop_schedule_expression
  start_schedule_expression = var.start_schedule_expression
  schedule_timezone         = var.schedule_timezone
  tags                      = local.common_tags
}
