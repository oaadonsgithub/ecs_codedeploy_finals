// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.karrio.name
}




