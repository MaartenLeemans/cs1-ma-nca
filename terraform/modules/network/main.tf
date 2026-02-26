resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cs1-vpc"
  }
}

# -------------------------
# Public subnets (hub)
# -------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cs1-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "cs1-public-b"
  }
}

# -------------------------
# App subnets (spoke – containers / web tier)
# -------------------------

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "cs1-app-a"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "cs1-app-b"
  }
}

# -------------------------
# DB subnets (spoke – database tier)
# -------------------------

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "cs1-db-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "cs1-db-b"
  }
}

# -------------------------
# Internet Gateway + public routing (hub)
# -------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cs1-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cs1-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------
# NAT Gateway + private routing (spokes)
# -------------------------
# Let op: NAT Gateway kost geld. Gebruik apply/destroy bewust.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "cs1-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "cs1-nat-gw"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cs1-private-rt"
  }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# App subnets gebruiken private route table
resource "aws_route_table_association" "app_a_assoc" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "app_b_assoc" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private_rt.id
}

# DB subnets gebruiken ook private route table
resource "aws_route_table_association" "db_a_assoc" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_b_assoc" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------
# Private DNS zone (Route 53)
# -------------------------

resource "aws_route53_zone" "private" {
  name = "internal.cs1.local"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  comment = "Private DNS zone for internal services (PaaS, DB, ECS)"
}