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
# VARIABLES
###############################################################################################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "AWS availability zone"
  type        = string
  default     = "eu-west-1a"
}

variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "prog-cloud-tp3"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "prenom" {
  description = "Author first name"
  type        = string
}

variable "my_ip" {
  description = "SSH CIDR"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.18.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "172.18.10.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "172.18.20.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.micro"
}

variable "tiers" {
  description = "3-tier architecture"
  type = map(object({
    role      = string
    subnet    = string
    public_ip = bool
  }))
  default = {
    web = {
      role      = "frontend"
      subnet    = "public"
      public_ip = true
    }
    api = {
      role      = "backend"
      subnet    = "public"
      public_ip = true
    }
    db = {
      role      = "database"
      subnet    = "private"
      public_ip = false
    }
  }
}
