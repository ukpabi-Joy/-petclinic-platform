# ---------------------------------------------------------------------------
# EBS CSI Driver IRSA role
#
# The driver runs as the ebs-csi-controller-sa service account in kube-system
# and assumes this role via the cluster OIDC provider. AmazonEBSCSIDriverPolicy
# grants the EC2 permissions needed to manage EBS volumes.
# ---------------------------------------------------------------------------
locals {
  # OIDC issuer hostpath, e.g. oidc.eks.eu-central-1.amazonaws.com/id/ABC123
  oidc_provider = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = {
    Name = "${local.name}-ebs-csi-driver"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_AmazonEBSCSIDriverPolicy" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ---------------------------------------------------------------------------
# Managed add-ons (all versions pinned)
# ---------------------------------------------------------------------------
# vpc-cni and kube-proxy are installed before the node group joins; coredns and
# the EBS CSI driver schedule pods and therefore need ready nodes.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = var.addon_versions["vpc-cni"]

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.name}-vpc-cni"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  addon_version = var.addon_versions["kube-proxy"]

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.name}-kube-proxy"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  addon_version = var.addon_versions["coredns"]

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.name}-coredns"
  }

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_versions["aws-ebs-csi-driver"]
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.name}-ebs-csi-driver"
  }

  depends_on = [aws_eks_node_group.this]
}
