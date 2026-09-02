output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR."
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs. EKS nodes and RDS live here."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs. Only load balancers live here."
  value       = aws_subnet.public[*].id
}

output "availability_zones" {
  description = "AZs the VPC spans."
  value       = local.azs
}
