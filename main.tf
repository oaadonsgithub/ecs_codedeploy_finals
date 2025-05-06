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
  vpc_id      = module.vpc.vpc_id
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
  vpc_id = module.vpc.vpc_id

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
  vpc_id      = module.vpc.vpc_id
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
  vpc_id      = module.vpc.vpc_id
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
      image     = "123456789012.dkr.ecr.us-west-2.amazonaws.com/karrio:latest"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
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
    subnets         = module.vpc.public_subnets
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
  name         = "web-ecr-repository"
  force_delete = true
}

resource "aws_ecs_cluster" "web_cluster" {
  name = "application_cluster"
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/frontend"
}


resource "aws_ecs_service" "frontend" {
  name                               = "frontend"
  cluster                            = aws_ecs_cluster.web_cluster.id
  task_definition                    = aws_ecs_task_definition.frontend_task.arn
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 300
  launch_type                        = "EC2"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 2
  force_new_deployment               = true

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg[0].arn
    container_name   = "web"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    aws_lb_listener.l_443,
    aws_lb_listener.l_8080
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count, load_balancer]
  }
}


resource "aws_ecs_task_definition" "frontend_task" {
  family = "frontend-task"

  container_definitions = jsonencode([{
    name      = "web"
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_account_region}.amazonaws.com/web-ecr-repository:latest"
    essential = true
    portMappings = [{ containerPort = 80 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.region
      }
    }
  }])

  requires_compatibilities = ["EC2"]
  memory                   = 1800
  cpu                      = 512
  execution_role_arn       = aws_iam_role.web_task_role.arn
}








resource "aws_codedeploy_app" "frontend" {
  compute_platform = "ECS"
  name             = "frontend-deploy"
}

resource "aws_codedeploy_deployment_group" "frontend" {
  app_name               = aws_codedeploy_app.frontend.name
  deployment_group_name  = "frontend-deploy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.web_cluster.name
    service_name = aws_ecs_service.frontend.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
  target_group_pair_info {
    target_group {
      name = aws_lb_target_group.web_tg[0].name # Blue
    }
    target_group {
      name = aws_lb_target_group.web_tg[1].name # Green
    }

    prod_traffic_route {
      listener_arns = [aws_lb_listener.l_443.arn]
    }

    test_traffic_route {
      listener_arns = [aws_lb_listener.l_8080.arn]
    }
  }
}
}
