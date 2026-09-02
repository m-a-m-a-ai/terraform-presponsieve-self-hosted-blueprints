output "cluster_name" {
  description = "Cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN. Required for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL without the scheme."
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

output "node_security_group_id" {
  description = "Security group attached to nodes. Grant RDS ingress from this."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  description = "IAM role assumed by nodes."
  value       = aws_iam_role.nodes.arn
}

output "update_kubeconfig_command" {
  description = "Copy-paste command to configure kubectl."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${data.aws_region.current.region}"
}

data "aws_region" "current" {}
