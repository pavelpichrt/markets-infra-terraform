resource "aws_ecs_task_definition" "stock_fetcher" {
  family                   = "stock-fetcher-task-${var.command}"
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn

  container_definitions = <<DEFINITION
[
  {
    "name": "stock-fetcher",
    "image": "${var.image}",
    "cpu": 512,
    "memory": 1024,
    "memoryReservation": 1024,
    "command": ["node", "bundle.js", "--task=${var.command}"],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.log_group_name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "stock_f_"
      }
    }
  }
]
DEFINITION
}

module "ecs_fargate_scheduled_task_workdays" {
  source                                      = "cn-terraform/ecs-fargate-scheduled-task/aws"
  version                                     = "1.0.7"
  event_rule_name                             = "stock-fetcher-scheduler-${var.command}"
  ecs_cluster_arn                             = var.ecs_cluster_arn
  event_rule_schedule_expression              = var.schedule
  event_target_ecs_target_subnets             = var.subnets
  event_target_ecs_target_assign_public_ip    = true
  event_target_ecs_target_task_definition_arn = aws_ecs_task_definition.stock_fetcher.arn
  ecs_execution_task_role_arn                 = var.task_role_arn
  name_preffix                                = var.command
  event_target_ecs_target_security_groups     = var.security_groups
}

resource "aws_iam_role_policy_attachment" "ecsEventsRole_policy" {
  role       = module.ecs_fargate_scheduled_task_workdays.aws_iam_role_policy_scheduled_task_cw_event_role_cloudwatch_policy_role
  policy_arn = var.ecs_events_role_arn
}
