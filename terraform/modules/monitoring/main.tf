data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

resource "aws_security_group" "monitoring" {
  name   = "cs1-monitoring-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9090
    to_port   = 9090
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  prometheus_config = templatefile("${path.module}/prometheus.tpl", {
    onprem_target = var.onprem_target
  })

  alert_rules = templatefile("${path.module}/alerts.tpl", {})
}

resource "aws_iam_role" "grafana_cloudwatch" {
  name = "grafana-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_policy" {
  role       = aws_iam_role.grafana_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_instance_profile" "grafana_profile" {
  name = "grafana-cloudwatch-profile"
  role = aws_iam_role.grafana_cloudwatch.name
}

resource "aws_instance" "monitoring" {

  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  subnet_id     = var.subnet_id
  key_name      = "cs1-key"

  iam_instance_profile = aws_iam_instance_profile.grafana_profile.name
  
  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  associate_public_ip_address = true

user_data = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  dnf update -y
  dnf install -y docker

  systemctl enable --now docker

  mkdir -p /opt/monitoring/prometheus

  cat > /opt/monitoring/prometheus/prometheus.yml <<'YML'
  global:
    scrape_interval: 15s

  scrape_configs:
    - job_name: 'node_exporter'
      static_configs:
        - targets: ['localhost:9100']
  YML

  # node_exporter
  docker rm -f node_exporter || true
  docker run -d --restart unless-stopped --name node_exporter \
    -p 9100:9100 prom/node-exporter

  # prometheus
  docker rm -f prometheus || true
  docker run -d --restart unless-stopped --name prometheus \
    -p 9090:9090 \
    -v /opt/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
    prom/prometheus

  # grafana
  docker rm -f grafana || true
  docker run -d --restart unless-stopped --name grafana \
    -p 3000:3000 grafana/grafana-oss

  docker ps -a
EOF

  tags = {
    Name = "cs1-monitoring-node"
  }
}
