// Politique d'assumption : seules les instances EC2 peuvent utiliser ce role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

// Role partage par les instances de la v1.
// Il reste volontairement minimal pour eviter les privileges inutiles.
resource "aws_iam_role" "ec2" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

// Politique applicative minimale.
// PutMetricData exige resources="*", donc la restriction se fait par condition de namespace.
data "aws_iam_policy_document" "ec2_metrics" {
  statement {
    sid       = "AllowOnlyNordCloudCustomMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = [var.metric_namespace]
    }
  }
}

// Politique separee pour documenter explicitement le droit accorde aux instances.
resource "aws_iam_policy" "ec2_metrics" {
  name        = "${var.name_prefix}-ec2-metrics"
  description = "Least-privilege policy for NordCloud custom metrics only"
  policy      = data.aws_iam_policy_document.ec2_metrics.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-metrics"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_metrics" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_metrics.arn
}

// Instance profile attache aux EC2.
// Terraform separe le role IAM et le profil consommable par EC2.
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-profile"
  })
}
