# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0run_makesomechanges

terraform {
  backend "remote" {
    organization = "oaa_dons"

    workspaces {
      name = "ci_automations"
    }
  }

  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.9.0"
      
    }
    aws = {
    source  = "hashicorp/aws"
    version = "~> 4.52.0"
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


#
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
          "ecs:DescribeServices",
          "sns:CreateTopic",
          "sns:Subscribe",
          "sns:Publish",
          "sns:GetTopicAttributes"
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
    resources = ["*"]
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
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

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
# 4. DNS & SSL Certificate
# ----------------------------
resource "aws_route53_zone" "main" {
  name = "ianthony.com"
}

resource "tls_private_key" "account_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.account_key.private_key_pem
  email_address           = "admin@ianthony.com"
}


# Optional: You are also creating a cert in AWS ACM
resource "aws_acm_certificate" "cert" {
  domain_name       = "karrio.ianthony.com"
  validation_method = "DNS"

  tags = {
    Environment = "prod"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_acm_certificate" "imported_cert" {
  private_key       = acme_certificate.cert.private_key_pem
  certificate_body  = acme_certificate.cert.certificate_pem
  certificate_chain = acme_certificate.cert.issuer_pem
}



# Save Let's Encrypt cert to disk
resource "local_file" "cert_pem" {
  content  = acme_certificate.cert.certificate_pem
  filename = "${path.module}/cert.pem"
}

resource "local_file" "key_pem" {
  content  = acme_certificate.cert.private_key_pem
  filename = "${path.module}/key.pem"
}




resource "acme_certificate" "cert" {
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "karrio.ianthony.com"

  dns_challenge {
    provider = "route53"
  }
}



# ----------------------------
# 5. Target Groups (Blue/Green) & load balancer
# ----------------------------

resource "aws_launch_template" "web" {
  name_prefix   = "qa-instance"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              mkdir -p /etc/nginx/ssl
              echo '${acme_certificate.cert.certificate_pem}' > /etc/nginx/ssl/cert.pem
              echo '${acme_certificate.cert.private_key_pem}' > /etc/nginx/ssl/key.pem
              cat > /etc/nginx/sites-available/default <<EOL
              server {
                  listen 443 ssl;
                  server_name ${var.domain_name};
                  ssl_certificate /etc/nginx/ssl/cert.pem;
                  ssl_certificate_key /etc/nginx/ssl/key.pem;

                  location / {
                      return 200 "Hello from secure Nginx!";
                  }
              }
              EOL
              systemctl restart nginx
              EOF
  )

  tags = {
    Name = "KarrioHospitalApp"
  }
}






# IAM Role and Instance Profile for ECS EC2 Instances
resource "aws_iam_role" "web" {
  name = "webRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_attach" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "web" {
  name = "qaInstanceProfile"
  role = aws_iam_role.web.name
}



resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = var.subnet_ids
  enable_deletion_protection = false
}

locals {
  target_groups = ["green", "blue"]
  active_index  = index(local.target_groups, var.active_color)
}


########TARGET GROUP START

resource "aws_lb_target_group" "blue" {
  name        = "blue-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "green" {
  name        = "green-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "prod_https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.imported_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}



resource "aws_lb_listener" "test_https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.imported_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}




resource "aws_iam_user_policy_attachment" "route53_full_access" {
  user       = "oaa_progmatic_01"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
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
          awslogs-region        = "us-west-1",
          awslogs-stream-prefix = "karrio"
        }
      }
    }
  ])
}

# ----------------------------
# 7. ECS Service with CodeDeploy
# ----------------------------

resource "aws_ecs_cluster" "main" {
  name = "karrio-cluster"
}




resource "aws_ecs_service" "app" {
  name            = "karrio-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.karrio_task.arn
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "karrio"
    container_port   = 3000
  }

  desired_count = 1
}

# ----------------------------
# 8. CodeDeploy Setup
# ----------------------------




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

