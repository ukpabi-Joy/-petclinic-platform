# AWS Load Balancer Controller

Installs the AWS Load Balancer Controller so that Kubernetes `Ingress` objects
with `ingressClassName: alb` provision AWS Application Load Balancers.

- **Chart version:** `1.8.1` (`eks/aws-load-balancer-controller`)
- **App version:** `v2.8.1`
- **Namespace:** `kube-system`
- **IAM:** IRSA role + policy created by `terraform/modules/alb-controller`

## Prerequisites

1. EKS cluster up with an IAM OIDC provider (the `eks` module creates one).
2. `terraform apply` in `environments/dev` so the IRSA role exists. Capture the
   role ARN:

   ```sh
   terraform -chdir=terraform/environments/dev output -raw alb_controller_role_arn
   ```

3. Put that ARN into `values.yaml` (`serviceAccount.annotations`), replacing
   `<ALB_CONTROLLER_ROLE_ARN>`.

## Install

```sh
# 1. Install the CRDs at the matching app version (v2.8.1).
kubectl apply -k \
  "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=v2.8.1"

# Alternatively, apply the raw CRD manifest for v2.8.1:
# kubectl apply -f \
#   https://raw.githubusercontent.com/aws/eks-charts/v2.8.1/stable/aws-load-balancer-controller/crds/crds.yaml

# 2. Add the Helm repo.
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 3. Install the controller (chart 1.8.1) into kube-system.
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.8.1 \
  --values values.yaml \
  --set-string serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$(terraform -chdir=../../terraform/environments/dev output -raw alb_controller_role_arn)"
```

## Verify

```sh
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
```

Both replicas should be `Running` in `kube-system`.
