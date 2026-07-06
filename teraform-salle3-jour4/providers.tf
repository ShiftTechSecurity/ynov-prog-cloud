terraform {
  # Version alignee avec les TPs precedents du depot.
  # Le provider AWS est utilise ici car les exercices deja presents ont ete adaptes sur AWS.
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    # State distant pour eviter de perdre l'etat Terraform entre deux postes.
    # Le state peut contenir des informations sensibles : il ne doit pas etre commite.
    bucket       = "tfstate-bucket-prog-cloud"
    key          = "prog-cloud/teraform-salle3-jour4/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  # La region reste parametrable pour pouvoir adapter le TP sans modifier le code.
  region = var.aws_region
}
