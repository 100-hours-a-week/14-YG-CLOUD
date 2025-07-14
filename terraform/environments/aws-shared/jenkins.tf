resource "aws_instance" "jenkins_server" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  subnet_id     = aws_subnet.aws_shared_subnet.id
  key_name      = var.aws_key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true # Add this line to associate a public IP

  tags = {
    Name = "aws-shared-jenkins"
    Environment = "aws-shared"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "aws-shared-jenkins-sg"
  description = "Allow Jenkins UI and SSH access"
  vpc_id      = aws_vpc.aws_shared_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-shared-jenkins-sg"
  }
}