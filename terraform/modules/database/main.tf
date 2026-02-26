########################################
# DB subnet group (private DB subnets)
########################################

resource "aws_db_subnet_group" "db_subnets" {
  name       = "cs1-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "cs1-db-subnet-group"
  }
}

########################################
# Security group voor RDS
########################################

resource "aws_security_group" "db_sg" {
  name        = "cs1-db-sg"
  description = "Allow PostgreSQL from ECS only"
  vpc_id      = var.vpc_id

  # Alleen verkeer vanaf ECS service SG op poort 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# RDS PostgreSQL instance (PaaS DB)
########################################

resource "aws_db_instance" "db" {
  identifier              = "cs1-db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible     = false          # geen public endpoint
  skip_final_snapshot     = true           # demo / schoolomgeving
  backup_retention_period = 0              # kan later hoger

  tags = {
    Name = "cs1-db"
  }
}

########################################
# Private DNS record in Route 53
########################################

resource "aws_route53_record" "db_record" {
  zone_id = var.private_zone_id
  name    = "db.internal.cs1.local"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.db.address]
}