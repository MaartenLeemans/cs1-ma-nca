output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "ecs_service_security_group_id" {
  value = aws_security_group.ecs_sg.id
}