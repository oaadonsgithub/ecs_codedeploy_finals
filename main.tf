# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  backend "remote" {
    organization = "oaa_dons"

    workspaces {
      name = "new_work_place"
    }
  }
}

provider "aws" {
  region = var.region
}

####Grant Permission to role 

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_policy" {
  name   = "ecs_policy"
  role   = aws_iam_role.ecs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ecs:CreateCluster"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "ecs:DescribeClusters"
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role" "web_task_role" {
  name = "web-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}




resource "aws_iam_policy" "ecs_task_definition_policy" {
  name        = "ecs_task_definition_policy"
  description = "Allow registering ECS task definition"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ecs_task_definition_attachment" {
  user       = "oaa_progmatic_01"
  policy_arn = aws_iam_policy.ecs_task_definition_policy.arn
}


resource "aws_iam_role_policy_attachment" "ECS_task_execution" {
  role       = aws_iam_role.web_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_policy" "codedeploy_create_policy" {
  name        = "codedeploy_create_policy"
  description = "Allow creating and managing CodeDeploy applications"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateApplication",
          "codedeploy:CreateDeploymentGroup",
          "codedeploy:GetApplication",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:UpdateApplication",
          "codedeploy:UpdateDeploymentGroup",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_user_policy_attachment" "codedeploy_create_attachment" {
  user       = "oaa_progmatic_01"
  policy_arn = aws_iam_policy.codedeploy_create_policy.arn
}


data "aws_iam_policy_document" "assume_by_codedeploy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codedeploy.json
}

data "aws_iam_policy_document" "codedeploy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "s3:GetObject"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [aws_iam_role.web_task_role.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]
    resources = [
      aws_ecs_service.frontend.id,
      aws_codedeploy_deployment_group.frontend.arn,
      "arn:aws:codedeploy:${var.region}:${var.aws_account_id}:deploymentconfig:*",
      aws_codedeploy_app.frontend.arn
    ]
  }
}

resource "aws_iam_role_policy" "codedeploy" {
  role   = aws_iam_role.codedeploy.name
  policy = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_iam_role_policy" "codedeploy_ecs" {
  name = "codedeploy-ecs-policy"
  role = aws_iam_role.codedeploy.name # Replace with your actual role reference if different

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "codedeploy:DeleteDeploymentGroup"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterTargets"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = "*"
      }
    ]
  })
}




######create security groups and scalling 


# ----------------------------
# 2. Security Groups
# ----------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow HTTP access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------
# 3. ECS Cluster & IAM
# ----------------------------
resource "aws_ecs_cluster" "this" {
  name = "karrio-cluster"
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_logs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


# ----------------------------
# 4. Application Load Balancer
# ----------------------------
resource "aws_lb" "main" {
  name               = "ecs-bluegreen-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group_blue.arn
  }
}

# ----------------------------
# 5. Target Groups (Blue/Green)
# ----------------------------
resource "aws_lb_target_group" "blue" {
  name        = "blue-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "green-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ----------------------------
# 6. ECS Task Definition
# ----------------------------

resource "aws_cloudwatch_log_group" "karrio" {
  name              = "/ecs/karrio"
  retention_in_days = 14
}



resource "aws_ecs_task_definition" "karrio_task" {
  family                   = "karrio-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "karrio"
      image     = "${var.aws_account_id}.dkr.ecr.${var.aws_account_region}.amazonaws.com/karrio:latest"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
       logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.karrio.name,
          awslogs-region        = "us-west-2",
          awslogs-stream-prefix = "karrio"
        }
      }
    }
  ])
}

# ----------------------------
# 7. ECS Service with CodeDeploy
# ----------------------------
resource "aws_ecs_service" "karrio" {
  name                               = "karrio-service"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.karrio_task.arn
  launch_type                        = "FARGATE"
  desired_count                      = 1
  platform_version                   = "LATEST"
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group_blue.arn
    container_name   = "karrio"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# ----------------------------
# 8. CodeDeploy Setup
# ----------------------------
resource "aws_codedeploy_app" "ecs_app" {
  name             = "karrio-cd-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "ecs_dg" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "karrio-deploy-group"
  service_role_arn       = "arn:aws:iam::537124950459:role/CodeDeploy-Service-role"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.karrio.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group_blue.name
      }
      target_group {
        name = aws_lb_target_group_green.name
      }

      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}



resource "aws_ecr_repository" "web_ecr_repo" {
  name         = "karrio"
  force_delete = true
}


# ----------------------------
# Setup alarm and Notification
# ----------------------------

resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = "oaaderibigbe@dons.usfca.edu" # Replace with your email
}


resource "aws_cloudwatch_log_metric_filter" "ecs_errors" {
  name           = "ecs-error-filter"
  log_group_name = aws_cloudwatch_log_group.karrio.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ECSAppErrors"
    namespace = "KarrioApp"
    value     = "1"
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_error_alarm" {
  alarm_name          = "ecs-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ECSAppErrors"
  namespace           = "KarrioApp"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  alarm_description   = "Triggers if ECS app logs an ERROR"
  alarm_actions       = [aws_sns_topic.ecs_alerts.arn]
}

