output "argocd_admin_password" {
  value = base64decode(data.kubernetes_secret.argocd_admin_secret.data.password)
  sensitive = true 
}
