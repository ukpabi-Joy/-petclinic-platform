output "zone_id" {
  description = "ID of the looked-up Route 53 hosted zone."
  value       = data.aws_route53_zone.this.zone_id
}

output "zone_name" {
  description = "Name of the hosted zone."
  value       = data.aws_route53_zone.this.name
}

output "name_servers" {
  description = "Name servers for the hosted zone."
  value       = data.aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate (apex + wildcard). Use this on the ALB Ingress."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain_name" {
  description = "Primary domain on the certificate."
  value       = aws_acm_certificate.this.domain_name
}

output "alias_record_fqdns" {
  description = "FQDNs of the A-alias records pointing at the ALB (empty until alb_dns_name/alb_zone_id are supplied)."
  value       = [for r in aws_route53_record.alias : r.fqdn]
}
