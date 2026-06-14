# Ingress

Exposes the Petclinic `api-gateway` to the internet via an AWS ALB.

```
Route53 (petclinic.joycloudsolution.online)
  -> ALB (HTTPS:443, HTTP:80->443 redirect, ACM cert)
    -> Ingress (ingressClassName: alb)
      -> api-gateway Service :8080
```

## Files

| File | Purpose |
|------|---------|
| `api-gateway-ingress.yaml` | ALB Ingress routing the app host to `api-gateway:8080` with HTTPS termination and HTTP→HTTPS redirect. |

## Prerequisites

1. AWS Load Balancer Controller installed (see `../alb-controller`).
2. DNS module applied so the ACM certificate exists.

## Apply

```sh
# Inject the ACM certificate ARN from Terraform, then apply.
CERT_ARN=$(terraform -chdir=../../terraform/environments/dev output -raw acm_certificate_arn)
sed "s#<ACM_CERTIFICATE_ARN>#${CERT_ARN}#" api-gateway-ingress.yaml | kubectl apply -f -
```

## Point DNS at the ALB

The ALB hostname is published on the Ingress once it is provisioned:

```sh
kubectl -n petclinic-dev get ingress api-gateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Feed that hostname (and the ALB's canonical hosted zone ID) back into the DNS
module via `alb_dns_name` / `alb_zone_id` and re-apply to create the
`petclinic.joycloudsolution.online` A-alias record (PetclinicPlatform31).
