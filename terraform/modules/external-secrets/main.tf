locals {
  name = "${var.project}-${var.environment}"

  # OIDC issuer hostpath, e.g. oidc.eks.eu-central-1.amazonaws.com/id/ABC123
  oidc_provider = replace(var.oidc_provider_url, "https://", "")

  # Default to every secret under this environment's path. The trailing wildcard
  # plus the "-??????" suffix that Secrets Manager appends are both matched by *.
  secret_arns = var.secret_resource_arns != null ? var.secret_resource_arns : [
    "arn:aws:secretsmanager:*:*:secret:${var.project}/${var.environment}/*",
  ]
}

# ---------------------------------------------------------------------------
# IAM policy — read access to the project's Secrets Manager secrets
# (PetclinicPlatform37). Scoped to GetSecretValue + DescribeSecret only.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  statement {
    sid    = "ReadSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = local.secret_arns
  }
}

resource "aws_iam_policy" "this" {
  name        = "${local.name}-external-secrets"
  description = "External Secrets Operator read access to Secrets Manager for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.this.json

  tags = {
    Name = "${local.name}-external-secrets"
  }
}

# ---------------------------------------------------------------------------
# IRSA role — trusts the cluster OIDC provider for the ESO service account in
# the external-secrets namespace (PetclinicPlatform37).
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${local.name}-external-secrets"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
