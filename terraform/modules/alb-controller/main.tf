locals {
  name = "${var.project}-${var.environment}"

  # OIDC issuer hostpath, e.g. oidc.eks.eu-central-1.amazonaws.com/id/ABC123
  oidc_provider = replace(var.oidc_provider_url, "https://", "")
}

# ---------------------------------------------------------------------------
# IAM policy — permissions the controller needs to create/manage ALBs (EC2 +
# ELBv2). Sourced from the upstream aws-load-balancer-controller project
# (see iam-policy.json). (PetclinicPlatform29)
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "this" {
  name        = "${local.name}-alb-controller"
  description = "AWS Load Balancer Controller permissions for ${var.cluster_name}"
  policy      = file("${path.module}/iam-policy.json")

  tags = {
    Name = "${local.name}-alb-controller"
  }
}

# ---------------------------------------------------------------------------
# IRSA role — trusts the cluster OIDC provider for the controller's service
# account in kube-system. (PetclinicPlatform29)
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
  name               = "${local.name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${local.name}-alb-controller"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
