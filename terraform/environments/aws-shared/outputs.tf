output "aws_vpc_id" {
  description = "The ID of the AWS shared VPC"
  value       = aws_vpc.aws_shared_vpc.id
}

output "aws_subnet_id" {
  description = "The ID of the AWS shared subnet"
  value       = aws_subnet.aws_shared_subnet.id
}

output "jenkins_public_ip" {
  description = "The public IP address of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.public_ip
}