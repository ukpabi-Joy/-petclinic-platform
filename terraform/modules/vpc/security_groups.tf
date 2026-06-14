# ---------------------------------------------------------------------------
# Baseline security groups.
#
# Groups and their rules are declared separately (aws_security_group_rule)
# so that mutually-referencing rules (nodes <-> cluster) don't create a
# circular dependency between the security group resources themselves.
# ---------------------------------------------------------------------------

# EKS cluster control plane.
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name}-eks-cluster"
  description = "EKS control plane to node communication"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-eks-cluster"
  }
}

# EKS worker nodes / pods.
resource "aws_security_group" "eks_nodes" {
  name        = "${local.name}-eks-nodes"
  description = "Traffic between EKS nodes and pods"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name                = "${local.name}-eks-nodes"
    (local.cluster_tag) = "owned"
  }
}

# Application Load Balancer.
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Public ALB ingress on 80/443"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-alb"
  }
}

# RDS database.
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "MySQL access from EKS nodes only"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name}-rds"
  }
}

# ----- Egress: allow all, for every security group -------------------------
resource "aws_security_group_rule" "eks_cluster_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.eks_cluster.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress"
}

resource "aws_security_group_rule" "eks_nodes_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.eks_nodes.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress (includes traffic to EKS nodes)"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.rds.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all egress"
}

# ----- EKS cluster ingress -------------------------------------------------
# Nodes -> control plane API.
resource "aws_security_group_rule" "eks_cluster_ingress_nodes_443" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  description              = "Node kubelets and pods to control plane API"
}

# ----- EKS node ingress ----------------------------------------------------
# Node-to-node and node-to-pod traffic.
resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  description       = "Node to node and node to pod traffic"
}

# Control plane -> kubelet / extension API server.
resource "aws_security_group_rule" "eks_nodes_ingress_cluster_kubelet" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
  description              = "Control plane to nodes (kubelet, ephemeral ports)"
}

resource "aws_security_group_rule" "eks_nodes_ingress_cluster_443" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  description              = "Control plane to nodes (extension API servers)"
}

# ALB -> nodes (application traffic).
resource "aws_security_group_rule" "eks_nodes_ingress_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
  description              = "ALB to node/pod application ports"
}

# ----- ALB ingress: public 80/443 -----------------------------------------
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Public HTTP"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Public HTTPS"
}

# ----- RDS ingress: 3306 from EKS nodes only -------------------------------
resource "aws_security_group_rule" "rds_ingress_nodes_3306" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_nodes.id
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  description              = "MySQL from EKS nodes"
}
