output "ecr_image_repository" {
  value = aws_ecr_repository.ecr_image_repository.repository_url
}

output "load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
}