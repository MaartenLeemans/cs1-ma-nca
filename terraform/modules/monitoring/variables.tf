variable "vpc_id" {
  description = "VPC where the monitoring instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the monitoring EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for monitoring node"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the monitoring instance"
  type        = string
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed to access Prometheus and Grafana"
  type        = string
}

variable "onprem_target" {
  description = "Optional on-prem node_exporter target (eg. 1.2.3.4:9100)"
  type        = string
  default     = ""
}