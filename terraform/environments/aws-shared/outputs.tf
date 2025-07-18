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

output "elk_public_ip" {
  description = "The public IP address of the ELK EC2 instance"
  value       = aws_instance.elk_server.public_ip
}

output "elk_elastic_ip" {
  description = "The Elastic IP address of the ELK EC2 instance"
  value       = aws_eip.elk_eip.public_ip
}

output "wireguard_public_ip" {
  description = "The public IP address of the WireGuard EC2 instance"
  value       = aws_instance.wireguard_server.public_ip
}

output "wireguard_elastic_ip" {
  description = "The Elastic IP address of the WireGuard EC2 instance"
  value       = aws_eip.wireguard_eip.public_ip
}