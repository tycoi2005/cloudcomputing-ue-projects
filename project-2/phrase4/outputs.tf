# phase4/outputs.tf

output "application_url" {
  description = "The public URL for the load-balanced web application."
  value       = "http://${aws_lb.main.dns_name}"
}