resource "aws_ecr_repository" "event-scheduler-repo" {
  name                 = "event-scheduler-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "event-scheduler-cluster" {
  name = "python-app-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "event-scheduler-service" {
  name            = "event-scheduler-service"
  cluster         = aws_ecs_cluster.event-scheduler-cluster.id
  task_definition = aws_ecs_task_definition.event-scheduler-task.arn
  desired_count   = 1
  iam_role        = aws_iam_role.event-scheduler-role.arn
  depends_on      = [aws_iam_role_policy.event-scheduler-policy, aws_ecs_task_definition.event-scheduler-task]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target.arn
    container_name   = "${var.environment}-lb-core"
    container_port   = var.container_port
  }
}

resource "aws_ecs_task_definition" "event-scheduler-task" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = aws_ecs_service.event-scheduler-service.load_balancer.container_name
      image     = "${var.ACCOUNT_ID}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.event-scheduler-repo.name}:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = 0
        }
      ]
    },
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = data.aws_ami.ubuntu.id
  iam_instance_profile = aws_iam_instance_profile.event-scheduler-agent.name
  security_groups      = [aws_security_group.allow_ecs.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.event-scheduler-cluster.name} >> /etc/ecs/ecs.config"
  instance_type        = var.instance_type
  # auto assign public IP
}

resource "aws_autoscaling_group" "ecs_auto_scaling_group" {
  name                 = "asg"
  vpc_zone_identifier  = [aws_subnet.public_subnet[0].id] #["subnet-78ab3600"] #
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
}