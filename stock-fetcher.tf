# ECR repo
resource "aws_ecr_repository" "stock_fetcher" {
  name                 = "stock-fetcher"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "stock_fetcher" {
  name = "stock-fetcher"
}

# Task  Execution role
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# App role
resource "aws_iam_role" "stock_fetcher_app_role" {
  name               = "stock-fetcher-app-role"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role_policy.json
}

resource "aws_iam_role_policy" "stock_fetcher_app_role_policy" {
  name   = "stock-fetch-app-role-policy"
  role   = aws_iam_role.stock_fetcher_app_role.id
  policy = data.aws_iam_policy_document.stock_fetcher_app_policy.json
}

data "aws_iam_policy_document" "app_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "stock_fetcher_app_policy" {
  statement {
    actions = [
      "ecs:DescribeClusters"
    ]

    resources = [
      aws_ecs_cluster.markets_app.arn,
    ]
  }
}

# This is needed for cloudwatch events to run tasks
resource "aws_iam_policy" "ecs_pass_role" {
  name   = "AmazonECSEventsTaskExecutionRole"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "${aws_iam_role.ecsTaskExecutionRole.arn}",
                "${aws_iam_role.stock_fetcher_app_role.arn}"
            ]
        }
    ]
}
EOF
}

# Task definitions
module "ecs_stock_fetcher_task_workday" {
  source              = "./modules/ecs-fargate-stock-fetcher-task"
  schedule            = "cron(0 22 ? * MON-FRI *)"
  command             = "workday"
  task_role_arn       = aws_iam_role.stock_fetcher_app_role.arn
  execution_role_arn  = aws_iam_role.ecsTaskExecutionRole.arn
  image               = "${aws_ecr_repository.stock_fetcher.repository_url}:latest"
  log_group_name      = aws_cloudwatch_log_group.stock_fetcher.name
  region              = var.region
  ecs_cluster_arn     = aws_ecs_cluster.markets_app.arn
  security_groups     = [aws_security_group.vpc_and_home.id]
  ecs_events_role_arn = aws_iam_policy.ecs_pass_role.arn
  subnets             = data.aws_subnet_ids.default.ids
}

module "ecs_stock_fetcher_task_weekly" {
  source              = "./modules/ecs-fargate-stock-fetcher-task"
  schedule            = "cron(0 22 ? * FRI *)"
  command             = "weekly"
  task_role_arn       = aws_iam_role.stock_fetcher_app_role.arn
  execution_role_arn  = aws_iam_role.ecsTaskExecutionRole.arn
  image               = "${aws_ecr_repository.stock_fetcher.repository_url}:latest"
  log_group_name      = aws_cloudwatch_log_group.stock_fetcher.name
  region              = var.region
  ecs_cluster_arn     = aws_ecs_cluster.markets_app.arn
  security_groups     = [aws_security_group.vpc_and_home.id]
  ecs_events_role_arn = aws_iam_policy.ecs_pass_role.arn
  subnets             = data.aws_subnet_ids.default.ids
}

# Outputs
output "ECR_URL_stock_fetcher" {
  value = aws_ecr_repository.stock_fetcher.repository_url
}
