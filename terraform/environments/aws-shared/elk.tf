# ELK Stack EC2 Instance
resource "aws_instance" "elk_server" {
  ami           = var.aws_ami
  instance_type = var.elk_instance_type
  subnet_id     = aws_subnet.aws_shared_subnet.id
  key_name      = var.aws_key_name
  vpc_security_group_ids = [aws_security_group.elk_sg.id]
  associate_public_ip_address = true

  # ELK 스택용 더 큰 스토리지
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  tags = {
    Name        = "aws-shared-elk"
    Environment = "aws-shared"
    Purpose     = "ELK Stack"
  }

  # 초기 설정 스크립트
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              pip3 install ansible
              
              # Docker 설치
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              usermod -aG docker ubuntu
              
              # 로그 폴더 준비
              mkdir -p /var/log/elasticsearch
              mkdir -p /var/log/kibana
              mkdir -p /var/log/logstash
              chown -R ubuntu:ubuntu /var/log/elasticsearch /var/log/kibana /var/log/logstash
              EOF
}

# ELK Stack Security Group
resource "aws_security_group" "elk_sg" {
  name        = "aws-shared-elk-sg"
  description = "Allow ELK Stack access"
  vpc_id      = aws_vpc.aws_shared_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (for Nginx reverse proxy)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (for Nginx with SSL)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Logstash
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # APM Server
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch cluster communication
  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-shared-elk-sg"
  }
}

# Elastic IP for ELK server
resource "aws_eip" "elk_eip" {
  instance = aws_instance.elk_server.id
  domain   = "vpc"

  tags = {
    Name = "aws-shared-elk-eip"
  }
}
