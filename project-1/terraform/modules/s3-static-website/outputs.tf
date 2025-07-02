output "static_website_id" {
  value = aws_s3_bucket.s3-static-website.id
}

output "static_website_arn" {
  value = aws_s3_bucket.s3-static-website.arn
}

output "static_website_regional_domain_name" {
  value = aws_s3_bucket.s3-static-website.bucket_regional_domain_name
}