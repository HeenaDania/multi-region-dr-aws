# VPC Outputs
output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  description = "ID of the secondary VPC"
  value       = aws_vpc.secondary.id
}

# S3 Outputs
output "primary_s3_bucket" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.bucket
}

output "secondary_s3_bucket" {
  description = "Name of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.bucket
}

# RDS Outputs
output "primary_rds_endpoint" {
  description = "Endpoint of the primary RDS instance"
  value       = aws_db_instance.primary.endpoint
}

output "secondary_rds_endpoint" {
  description = "Endpoint of the secondary RDS instance"
  value       = aws_db_instance.secondary_replica.endpoint
}

# EC2 Outputs
output "primary_alb_dns" {
  description = "DNS name of the primary application load balancer"
  value       = aws_lb.primary.dns_name
}

output "secondary_alb_dns" {
  description = "DNS name of the secondary application load balancer"
  value       = aws_lb.secondary.dns_name
}

# Route 53 Outputs
output "application_dns" {
  description = "Application DNS name"
  value       = "app.${var.domain_name}"
}
