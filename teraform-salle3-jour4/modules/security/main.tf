// Security Group du tier presentation.
// Il recoit le trafic utilisateur public et l'administration SSH restreinte.
resource "aws_security_group" "web" {
  name                   = "${var.name_prefix}-sg-web"
  description            = "Presentation tier security group"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc_id

  timeouts {
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-web"
    Tier = "presentation"
  })
}

// Security Group du tier application.
// Il n'expose aucun port a Internet et attend uniquement le trafic du SG web.
resource "aws_security_group" "app" {
  name                   = "${var.name_prefix}-sg-app"
  description            = "Application tier security group"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc_id

  timeouts {
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-app"
    Tier = "application"
  })
}

// Security Group du tier donnees.
// Il accepte uniquement le flux applicatif, jamais le web ni Internet.
resource "aws_security_group" "db" {
  name                   = "${var.name_prefix}-sg-db"
  description            = "Data tier security group"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc_id

  timeouts {
    delete = "30m"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-db"
    Tier = "data"
  })
}

locals {
  tier_security_groups = {
    web = aws_security_group.web.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}

// HTTP public pour rendre l'interface de presentation testable.
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from Internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

// HTTPS public prevu pour une cible plus realiste, meme si la v1 ne provisionne pas de certificat.
resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from Internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

// Administration limitee a une IP/CIDR equipe.
// Cette regle evite l'exposition SSH globale en 0.0.0.0/0.
resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH from admin CIDR"
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

// Resolution DNS necessaire aux installs systeme et clients internes.
resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  for_each = local.tier_security_groups

  security_group_id = each.value
  description       = "DNS UDP to VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  for_each = local.tier_security_groups

  security_group_id = each.value
  description       = "DNS TCP to VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  ip_protocol       = "tcp"
  to_port           = 53
}

// Sortie HTTPS limitee pour installer les paquets au premier boot.
// Les tiers app/db restent sans IP publique ; la sortie passe par NAT si active.
resource "aws_vpc_security_group_egress_rule" "package_https" {
  for_each = local.tier_security_groups

  security_group_id = each.value
  description       = "HTTPS to package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "package_http" {
  for_each = local.tier_security_groups

  security_group_id = each.value
  description       = "HTTP to package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

// Flux metier web -> application.
// L'origine est un Security Group, pas un CIDR, pour suivre dynamiquement les instances du tier web.
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application traffic from presentation tier"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
}

// Flux donnees application -> database.
// Aucune regle directe web -> db n'est creee.
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Database traffic from application tier"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  ip_protocol                  = "tcp"
  to_port                      = var.db_port
}

// Egress web limite vers le port applicatif.
// Les Security Groups AWS sont stateful : les reponses aux flux entrants autorises restent possibles.
resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id            = aws_security_group.web.id
  description                  = "Only presentation to application"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
}

// Egress app limite vers le port donnees.
// Cela applique le moindre privilege reseau entre les couches internes.
resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Only application to data"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = var.db_port
  ip_protocol                  = "tcp"
  to_port                      = var.db_port
}
