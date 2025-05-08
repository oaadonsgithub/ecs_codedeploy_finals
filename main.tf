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

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
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
  name = "ianthony.com"  # Optional: only needed if you want to manage the hosted zone too
}

# ACM Certificate for subdomain
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

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}


resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}



resource "tls_private_key" "account_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.account_key.private_key_pem
  email_address          = "admin@ianthony.com"
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
apt-get update -y
apt-get install -y docker.io git curl nginx certbot python3-certbot-nginx ufw
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable
su - ubuntu -c "git clone https://github.com/oaadonsgithub/ecs_codedeploy_finals.git /home/ubuntu/app"
cd /home/ubuntu/app/hospital-auth-app
npm init -y
apt install -y nginx
sudo ufw allow 'Nginx HTTP'
sudo ufw reload
npm i express body-parser connect-mongo express-session jsonwebtoken mongoose 
npm install -g nodemon
npm install dotenv
npm install passport
npm install passport-jwt passport
npm install passport passport-local
chmod +x setup_ssl.sh
./setup_ssl.sh

nodemon passport passport-jwt passport-local


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



resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids
  target_group_arns         = [aws_lb_target_group.web_tg[0].arn]


  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  health_check_type = "EC2"
  force_delete      = true

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web_lb" {
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





# For Fargate ECS service
resource "aws_lb_target_group" "fargate_tg" {
  name        = "fargate-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  

  health_check {
    path = "/"
  }
}

# For EC2 Auto Scaling Group
resource "aws_lb_target_group" "web_tg" {

  count        = length(local.target_groups)

  name_prefix = "web${count.index}-"

  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"  

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200,301,302,404"
  }

  lifecycle {
    # Ensure the name conforms to valid naming rules
    ignore_changes = [name]
  }
}


#resource "aws_lb_listener" "http_listener" {
#  load_balancer_arn = aws_lb.web_lb.arn
#  port              = 8081
#  protocol          = "HTTP"
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.fargate_tg.arn  
#  }
#}



resource "aws_alb_listener" "l_80" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    target_group_arn = aws_lb_target_group.web_tg[0].arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "l_8080" {
  load_balancer_arn = aws_lb.web_lb.id
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg[1].arn
  }
}

resource "aws_lb_listener" "l_443" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_tg.arn
  }

  depends_on = [aws_lb_target_group.web_tg]

  lifecycle {
    ignore_changes = [default_action]
  }
}


resource "aws_autoscaling_attachment" "asg_alb_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn    = aws_lb_target_group.web_tg[local.active_index].arn
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
    security_groups = [aws_security_group.web_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_tg.arn
    container_name   = "karrio"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      platform_version,
      load_balancer
    ]
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
  service_role_arn       = "arn:aws:iam::537124950459:role/codedeploy"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"


  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.karrio.name
  }

  load_balancer_info {
  target_group_pair_info {
    target_group {
      name = aws_lb_target_group.web_tg[0].name
    }
    target_group {
      name = aws_lb_target_group.web_tg[1].name
    }

    prod_traffic_route {
      listener_arns = [aws_alb_listener.l_80.arn]
    }
  }
}


  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
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

