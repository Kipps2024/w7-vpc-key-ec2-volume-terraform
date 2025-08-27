# version.tf


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
#output.tf

#main.tf

// vpc code 
resource "aws_vpc" "vpc1" {
  cidr_block           = "172.120.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "utc-app"
    env  = "Dev"
    Team = "DevOps"
  }
}
# Internet gateway

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "utc-app"
    env  = "Dev"
    Team = "DevOps"
  }
}
# subenet public 

resource "aws_subnet" "pusub1" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = true
  cidr_block              = "172.120.1.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-useast-1a"
  }
}
resource "aws_subnet" "pusub2" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = true
  cidr_block              = "172.120.2.0/24"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "public-useast-1b"
  }
}
// private subnets

resource "aws_subnet" "privsub1" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = "us-east-1a"
  cidr_block        = "172.120.3.0/24"
  tags = {
    Name = "private-us-east-1a"
  }
}
resource "aws_subnet" "privsub2" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = "us-east-1b"
  cidr_block        = "172.120.4.0/24"
  tags = {
    Name = "private-us-east-1b"
  }
}

# Nat gateway


resource "aws_eip" "eip1" {

}
resource "aws_nat_gateway" "gtw1" {
  subnet_id     = aws_subnet.pusub1.id
  allocation_id = aws_eip.eip1.id
  tags = {
    Name = "Nategateway"
    env  = "Dev"
  }
}


# Private route table


resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gtw1.id
  }
}

#public route table 

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}

# private route table association


resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.privsub1.id
  route_table_id = aws_route_table.rt1.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.privsub2.id
  route_table_id = aws_route_table.rt1.id
}

# public  route table association


resource "aws_route_table_association" "rtpub1" {
  subnet_id      = aws_subnet.pusub1.id
  route_table_id = aws_route_table.rt2.id
}
resource "aws_route_table_association" "rtpub2" {
  subnet_id      = aws_subnet.pusub2.id
  route_table_id = aws_route_table.rt2.id
}




#ec2.tf

resource "aws_instance" "server1" {
  ami                    = "ami-02f624c08a83ca16f"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pusub1.id
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  //key_name = 
  user_data = filebase64("setup.sh")

  tags = {
    Name = "Terraform_instance"
  }
}

#keypair.tf

# Generate a new RSA key pair locally

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# public key in aws


resource "aws_key_pair" "key1" {
  key_name   = "awsterraformkey"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# download key


resource "local_file" "localf" {
  filename        = "awsterraformkey.pem"
  content         = tls_private_key.ssh_key.private_key_openssh
  file_permission = 0400
}

