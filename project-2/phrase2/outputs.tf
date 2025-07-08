output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}


# for phrase 3

# VPC ID
output "vpc_id" {
  description = "VPC ID to reuse for RDS and Cloud9"
  value       = aws_vpc.main.id
}

# Public Subnet(s)
output "public_subnet_ids" {
  description = "Public subnet IDs for EC2 or Cloud9"
  value       = aws_subnet.public[*].id
}

output "private_subnet_id_1" {
  description = "Private subnet ID in AZ 1"
  value       = aws_subnet.private_1.id
}

output "private_subnet_id_2" {
  description = "Private subnet ID in AZ 2"
  value       = aws_subnet.private_2.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.natgw.id
}

# EC2 Instance ID
output "ec2_instance_id" {
  description = "Web app EC2 instance ID"
  value       = aws_instance.web.id
}

# EC2 Instance Public IP (for app access or SSH)
output "ec2_public_ip" {
  description = "Public IP of EC2 instance hosting the app"
  value       = aws_instance.web.public_ip
}

# Security Group ID (to reuse for RDS inbound rules)
output "web_sg_id" {
  description = "Security Group used for the EC2 web instance"
  value       = aws_security_group.web_sg.id
}

output "aws_region" {
  value = var.aws_region
}
