output "ecr_image_repository" {
  value = aws_ecr_repository.ecr_image_repository.repository_url
}