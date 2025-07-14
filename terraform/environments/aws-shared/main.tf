provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "aws_shared_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name = "aws-shared-vpc"
  }
}

resource "aws_subnet" "aws_shared_subnet" {
  vpc_id     = aws_vpc.aws_shared_vpc.id
  cidr_block = var.aws_subnet_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-shared-subnet"
  }
}

resource "aws_internet_gateway" "aws_shared_igw" {
  vpc_id = aws_vpc.aws_shared_vpc.id
  tags = {
    Name = "aws-shared-igw"
  }
}

resource "aws_route_table" "aws_shared_rt" {
  vpc_id = aws_vpc.aws_shared_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_shared_igw.id
  }
  tags = {
    Name = "aws-shared-rt"
  }
}

resource "aws_route_table_association" "aws_shared_rta" {
  subnet_id      = aws_subnet.aws_shared_subnet.id
  route_table_id = aws_route_table.aws_shared_rt.id
}
