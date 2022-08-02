resource "aws_iam_role" "event-scheduler-role" {
  name = "event-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "event-scheduler-role"
  }
}

resource "aws_iam_role_policy" "event-scheduler-policy" {
  name = "event-scheduler-policy"
  role = aws_iam_role.event-scheduler-role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ECSTaskManagement",
        "Effect" : "Allow",
        "Action" : [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:Describe*",
          "ec2:DetachNetworkInterface",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:Get*",
          "route53:List*",
          "route53:UpdateHealthCheck",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:Get*",
          "servicediscovery:List*",
          "servicediscovery:RegisterInstance",
          "servicediscovery:UpdateInstanceCustomHealthStatus"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AutoScaling",
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:Describe*"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AutoScalingManagement",
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DeletePolicy",
          "autoscaling:PutScalingPolicy",
          "autoscaling:SetInstanceProtection",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "autoscaling:ResourceTag/AmazonECSManaged" : "false"
          }
        }
      },
      {
        "Sid" : "AutoScalingPlanManagement",
        "Effect" : "Allow",
        "Action" : [
          "autoscaling-plans:CreateScalingPlan",
          "autoscaling-plans:DeleteScalingPlan",
          "autoscaling-plans:DescribeScalingPlans"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "CWAlarmManagement",
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm"
        ],
        "Resource" : "arn:aws:cloudwatch:*:*:alarm:*"
      },
      {
        "Sid" : "ECSTagging",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:network-interface/*"
      },
      {
        "Sid" : "CWLogGroupManagement",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:/aws/ecs/*"
      },
      {
        "Sid" : "CWLogStreamManagement",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"
      },
      {
        "Sid" : "ExecuteCommandSessionManagement",
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeSessions"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "ExecuteCommand",
        "Effect" : "Allow",
        "Action" : [
          "ssm:StartSession"
        ],
        "Resource" : [
          "arn:aws:ecs:*:*:task/*",
          "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand"
        ]
      }] }

  )
}

data "aws_iam_policy_document" "event-scheduler-agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event-scheduler-agent" {
  name               = "event-scheduler-agent"
  assume_role_policy = data.aws_iam_policy_document.event-scheduler-agent.json
}

resource "aws_iam_instance_profile" "event-scheduler-agent" {
  name = "event-scheduler-agent"
  role = aws_iam_role.event-scheduler-agent.name
}