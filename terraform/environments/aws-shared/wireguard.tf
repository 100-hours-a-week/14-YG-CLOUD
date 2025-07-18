# WireGuard VPN 서버 설정
# AWS로 마이그레이션된 WireGuard VPN 인프라

# SSH 키 페어 생성
resource "aws_key_pair" "lsh_study_key" {
  key_name   = "lsh-study-key"
  public_key = file("~/.ssh/lsh-study-key.pub")
  
  tags = {
    Name = "lsh-study-key"
  }
}

# WireGuard VPN 보안 그룹
resource "aws_security_group" "wireguard_sg" {
  name        = "aws-shared-wireguard-sg"
  description = "Security group for WireGuard VPN server"
  vpc_id      = aws_vpc.aws_shared_vpc.id

  # SSH 접근 (관리용)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WireGuard VPN 포트 (UDP 51820)
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-shared-wireguard-sg"
  }
}

# WireGuard VPN 서버 인스턴스
resource "aws_instance" "wireguard_server" {
  ami           = "ami-0ea5eb4b05645aa8a" # Ubuntu 22.04 LTS (ap-northeast-2)
  instance_type = "t3.micro"  # 비용 효율적인 최소 사양 (1GB RAM, 2 vCPU)
  
  subnet_id                   = aws_subnet.aws_shared_subnet.id
  vpc_security_group_ids      = [aws_security_group.wireguard_sg.id]
  associate_public_ip_address = true
  key_name                   = aws_key_pair.lsh_study_key.key_name

  # EBS 최적화 및 스토리지 설정
  ebs_optimized = true
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    tags = {
      Name = "aws-shared-wireguard-root"
    }
  }

  # 인스턴스 초기 설정
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y wireguard-tools ufw
    
    # UFW 기본 설정
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 51820/udp
    echo "y" | ufw enable
    
    # IP 포워딩 활성화
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    sysctl -p
    
    # WireGuard 디렉토리 생성
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
    
    # 로그 설정
    echo "WireGuard VPN server initialization completed at $(date)" >> /var/log/wireguard-init.log
  EOF

  tags = {
    Name = "aws-shared-wireguard"
    Role = "VPN Server"
    Environment = "shared"
  }
}

# WireGuard 전용 Elastic IP
resource "aws_eip" "wireguard_eip" {
  instance = aws_instance.wireguard_server.id
  domain   = "vpc"
  
  tags = {
    Name = "aws-shared-wireguard-eip"
  }
  
  depends_on = [aws_internet_gateway.aws_shared_igw]
}
