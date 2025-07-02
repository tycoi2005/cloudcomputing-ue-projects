output "cloudfront_domain_name" {
  value = "http://${module.cloud_front.cloudfront_distribution_domain_name}"
}