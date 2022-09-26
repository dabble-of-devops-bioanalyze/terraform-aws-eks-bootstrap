data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "helm" {
  name = var.aws_route53_zone_name
}

locals {
  aws_route53_zone_id = data.aws_route53_zone.helm.zone_id
}

###########################################################################
# AWS EKS Metrics Server
###########################################################################
#
## https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html
#
resource "null_resource" "install_metrics_server" {
  depends_on = [
  ]
  # Removing always triggers from the main module.
  provisioner "local-exec" {
    command     = <<EOT
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
EOT
    environment = {
      AWS_REGION         = var.region
      AWS_DEFAULT_REGION = var.region
    }
  }
}

###########################################################################
# Cert Manager
###########################################################################

resource "helm_release" "cert_manager" {
  depends_on = [
  ]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "v1.9.1"
  create_namespace = true
  wait             = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

output "helm_release_cert_manager" {
  value = helm_release.cert_manager
}
#######################################################
# ingress
#######################################################

resource "helm_release" "ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = "4.2.5"
  create_namespace = true
  wait             = true
}

output "helm_release_ingress" {
  description = "Helm release ingress"
  value       = helm_release.ingress
}

data "kubernetes_service" "ingress" {
  depends_on = [
    helm_release.ingress,
  ]
  metadata {
    name      = "ingress-nginx-ingress-controller"
    namespace = "ingress-nginx"
  }
}

output "kubernetes_service_ingress" {
  value = data.kubernetes_service.ingress
}

###########################################################################
# External DNS
###########################################################################

resource "helm_release" "external_dns" {
  depends_on = [
  ]
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.11.0"
  namespace  = "default"
  timeout    = 600

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.roleArn"
    value = var.eks_external_dns_role_arn
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "txtOwnerID"
    value = "/hostedzone/${local.aws_route53_zone_id}"
  }
}

output "helm_release_external_dns" {
  value = helm_release.external_dns
}
