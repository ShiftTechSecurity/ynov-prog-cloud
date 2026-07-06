// EventBridge Scheduler assume ce role uniquement si l'option FinOps est activee.
data "aws_iam_policy_document" "scheduler_assume_role" {
  count = var.enable_schedule ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

// Droits limites au stop/start des instances gerees par ce dossier.
data "aws_iam_policy_document" "scheduler_permissions" {
  count = var.enable_schedule ? 1 : 0

  statement {
    sid       = "AllowStopStartOnlyManagedInstances"
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = values(var.instance_arns)
  }
}

// Role dedie au scheduler pour ne pas reutiliser le role applicatif EC2.
resource "aws_iam_role" "scheduler" {
  count = var.enable_schedule ? 1 : 0

  name               = "${var.name_prefix}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-scheduler-role"
  })
}

resource "aws_iam_role_policy" "scheduler" {
  count = var.enable_schedule ? 1 : 0

  name   = "${var.name_prefix}-scheduler-policy"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler_permissions[0].json
}

// Arret automatique des environnements non-prod.
// Desactive en production par la condition portee dans le module racine.
resource "aws_scheduler_schedule" "stop" {
  count = var.enable_schedule ? 1 : 0

  name                         = "${var.name_prefix}-stop-weekday-evening"
  schedule_expression          = var.stop_schedule_expression
  schedule_expression_timezone = var.schedule_timezone
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler[0].arn
    input = jsonencode({
      InstanceIds = values(var.instance_ids)
    })
  }
}

// Redemarrage automatique des environnements non-prod.
resource "aws_scheduler_schedule" "start" {
  count = var.enable_schedule ? 1 : 0

  name                         = "${var.name_prefix}-start-weekday-morning"
  schedule_expression          = var.start_schedule_expression
  schedule_expression_timezone = var.schedule_timezone
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler[0].arn
    input = jsonencode({
      InstanceIds = values(var.instance_ids)
    })
  }
}
