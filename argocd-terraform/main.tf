resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    
    labels = {
      "name"                               = "argocd"
      "terraform.managed-by"               = "true"
      "argocd.argoproj.io/core-component"  = "true" 
    }
    
    annotations = {
      "name" = "argocd-namespace"
    }
  }
}

resource "helm_release" "argocd_ha_bundled" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.1.0"
  namespace        = kubernetes_namespace.argocd.metadata.0.name
  create_namespace = false   
  
  wait             = true
  timeout          = 600
  
 
  values = [<<-EOF
    redis-ha:
      enabled: true

    # 2. Scale the core components for High Availability
    controller:
      replicas: 2
    server:
      replicas: 2
    repoServer:
      replicas: 2
    applicationSet:
      replicas: 2
  EOF
  ]
  depends_on = [
    kubernetes_namespace.argocd
  ]
}


data "kubernetes_secret" "argocd_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata.0.name
  }
  

  depends_on = [
    helm_release.argocd_ha_bundled
  ]
}