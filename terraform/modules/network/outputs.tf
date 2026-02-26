output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
}

output "app_subnet_ids" {
  value = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id,
  ]
}

output "db_subnet_ids" {
  value = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id,
  ]
}

output "private_zone_id" {
  value = aws_route53_zone.private.id
}