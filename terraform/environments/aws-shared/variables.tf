variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the AWS shared VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR block for the AWS shared subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_availability_zone" {
  description = "Availability Zone for the AWS shared subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "aws_shared_public_subnet_cidr" {
  description = "CIDR block for the AWS shared public subnet"
  type        = string
}

variable "aws_shared_private_subnet_cidr" {
  description = "CIDR block for the AWS shared private subnet"
  type        = string
}

variable "aws_ami" {
  description = "AMI ID for Jenkins EC2 instance"
  type        = string
  default     = "ami-0abcdef1234567890" # Replace with a valid Ubuntu 22.04 LTS AMI ID for ap-northeast-2
}

variable "aws_instance_type" {
  description = "Instance type for Jenkins EC2 instance"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4 GB Memory
}

variable "aws_key_name" {
  description = "Key pair name for Jenkins EC2 instance SSH access"
  type        = string
}

# ELK Stack variables
variable "elk_instance_type" {
  description = "Instance type for ELK Stack EC2 instance"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4 GB Memory
}
