provider "aws" {
  region = "eu-central-1"
}

#==============create VPC=================

resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/26"
  enable_dns_hostnames = true

  tags = {
    Name = "Myvpc"
  }
}

#=============create subnets===============

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Sub1"
  }
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.16/28"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Sub2"
  }
}

#==============create IGW====================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Myvpc_Intenet_Gateway"
  }
}

#==============locals=========================

locals {
  key_name         = "frankfurtkey"
  private_key_path = "~/Desktop/terraform/frankfurtkey.pem"
}

#==============create instances===============

resource "aws_instance" "vm1" {
  ami                         = "ami-0fbc0724a0721c688"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  availability_zone           = "eu-central-1a"
  subnet_id                   = aws_subnet.sub1.id
  key_name                    = local.key_name
  vpc_security_group_ids      = [aws_security_group.vm_secgroup.id]
  user_data                   = <<-EOF
                                Enable-PSRemoting
                                EOF

  tags = {
    Name = "VM1"
  }
}

resource "aws_instance" "vm2" {
  ami                         = "ami-0fbc0724a0721c688"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  availability_zone           = "eu-central-1b"
  subnet_id                   = aws_subnet.sub2.id
  key_name                    = local.key_name
  vpc_security_group_ids      = [aws_security_group.vm_secgroup.id]
  user_data                   = <<-EOF
                                Enable-PSRemoting
                                EOF

  tags = {
    Name = "VM2"
  }
}

#==============Route Table==============

resource "aws_route_table" "rtmyvpc" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Myvpc_Route_Table"
  }
}

#==========Create the Internet Access======

resource "aws_route" "MyVPC_internet_access" {
  route_table_id         = aws_route_table.rtmyvpc.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#======Associate the Route Table with the Subnet==============

resource "aws_route_table_association" "My_VPC_association1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rtmyvpc.id
}
resource "aws_route_table_association" "My_VPC_association2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rtmyvpc.id
}


#=============Target Groups==============

resource "aws_lb_target_group" "vms" {
  name     = "vmstg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.myvpc.id
}

resource "aws_lb_target_group_attachment" "tgavm1" {
  target_group_arn = aws_lb_target_group.vms.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tgavm2" {
  target_group_arn = aws_lb_target_group.vms.arn
  target_id        = aws_instance.vm2.id
  port             = 80
}

#==============NetLB=====================

resource "aws_lb" "nlb" {
  name                       = "mynlb"
  internal                   = "false"
  load_balancer_type         = "network"
  subnets                    = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  enable_deletion_protection = false

  tags = {
    Name = "NetworkLB"
  }
}

resource "aws_lb_listener" "tcp80" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vms.arn
  }
}

#=============Sec_group=================

resource "aws_security_group" "vm_secgroup" {
  name        = "allow_http_rdp_winrm"
  description = "Allow Http-rdp-winrm"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "Http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Rdp"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Winrm"
    from_port   = 5985
    to_port     = 5985
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
    Name = "allow_http_rdp_winrm"
  }
}
