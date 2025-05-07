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

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.karrio_task.arn
}


output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.ecs_app.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.ecs_dg.deployment_group_name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for ECS"
  value       = aws_cloudwatch_log_group.karrio.name
}



