locals {
  name = "${var.project}-${var.environment}"

  # ACM SANs default to the wildcard for the apex so the cert covers both
  # joycloudsolution.online and *.joycloudsolution.online.
  sans = var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain_name}"]

  # Names to alias at the ALB. Default to the apex when none are supplied.
  alias_names = length(var.alias_record_names) > 0 ? var.alias_record_names : [var.domain_name]

  # Only create the alias records once the ALB exists (both inputs supplied).
  create_alias = var.alb_dns_name != null && var.alb_zone_id != null
}

# ---------------------------------------------------------------------------
# Hosted zone (looked up, never created — PetclinicPlatform28)
# ---------------------------------------------------------------------------
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# ---------------------------------------------------------------------------
# ACM certificate — apex + wildcard, DNS-validated (PetclinicPlatform28)
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = local.sans
  validation_method         = "DNS"

  tags = {
    Name = "${local.name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# One validation record per distinct name on the certificate.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

# ---------------------------------------------------------------------------
# A-alias records pointing the app hostname(s) at the ALB (PetclinicPlatform31)
#
# The ALB is provisioned by the AWS Load Balancer Controller from the Ingress,
# not by Terraform. Supply alb_dns_name + alb_zone_id (e.g. from a
# `data "aws_lb"` lookup, or the Ingress status) once it exists; until then
# these records are skipped so `terraform validate`/`plan` succeed.
# ---------------------------------------------------------------------------
resource "aws_route53_record" "alias" {
  for_each = local.create_alias ? toset(local.alias_names) : toset([])

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
