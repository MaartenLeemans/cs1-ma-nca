output "vpc_id" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.computer.alb_dns_name
}

output "db_endpoint" {
  value = module.database.db_endpoint
}