output "cloudfront_domain_name" {
  value = "http://${module.cloud_front.cloudfront_distribution_domain_name}"
}

output "alb_domain_name" {
  description = "Public endpoint of the ALB backend"
  value       = "http://${module.lambda_alb_backend.alb_dns_name}"
}