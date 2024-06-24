variable "aws_region" {
  description = "AWS Region to be used"
  type        = string
}

variable "ecs_container_cpu" {
  description = "CPU for the ECS container"
  type        = string
}

variable "ecs_container_memory" {
  description = "Memory for the ECS Container"
  type        = string
}

variable "ecs_app_hello_world_tag" {
  description = "Tag image for the hello world app"
  type        = string
}
