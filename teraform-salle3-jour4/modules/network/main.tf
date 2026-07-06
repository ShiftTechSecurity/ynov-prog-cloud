// VPC dedie a la mission NordCloud.
// Un reseau separe evite les collisions avec d'autres TPs et simplifie l'audit.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

// Subnet public du tier presentation.
// C'est le seul subnet ou une ressource peut obtenir une IP publique au lancement.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-web-subnet"
    Tier = "presentation"
  })
}

// Subnet prive du tier application.
// Aucune IP publique n'est attribuee : l'application est jointe uniquement via le SG web.
resource "aws_subnet" "app" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-app-subnet"
    Tier = "application"
  })
}

// Subnet prive du tier donnees.
// La base ou le service de donnees ne doit jamais etre accessible directement depuis Internet.
resource "aws_subnet" "data" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.data_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-data-subnet"
    Tier = "data"
  })
}

// Internet Gateway necessaire uniquement pour exposer le tier presentation.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

// NAT Gateway utilise par les tiers prives pendant le bootstrap.
// Il permet d'installer PostgreSQL, Python et dependances sans exposer app/db en public.
resource "aws_eip" "nat" {
  count = var.enable_private_nat ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.enable_private_nat ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

// Route publique : seul le subnet presentation est associe a cette table.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

// Route table privee sans route Internet.
// Choix volontaire pour reduire les couts et eviter un NAT Gateway dans cette v1 de TP.
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_private_nat ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-app-rt"
  })
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id
}

// Route table donnees separee pour rendre l'isolement explicite dans le plan Terraform.
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_private_nat ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-data-rt"
  })
}

resource "aws_route_table_association" "data" {
  subnet_id      = aws_subnet.data.id
  route_table_id = aws_route_table.data.id
}
