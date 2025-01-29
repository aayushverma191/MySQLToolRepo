terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}



provider "aws" {
  region = var.region_name
}

variable "region_name" {
  type        = string
  default     = "us-east-1"
  description = "enter region name"
}

########################################
#               add backend ##Variables not allowed
######################################

terraform {
  backend "s3" {
    bucket         = "final-tool-ninja-batch28"
    key            = "east.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

########################################
#               network moduble (vpc)
######################################


##use default vpc
data "aws_vpc" "default" {
  default = true
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
output "default_vpc_cidr" {
  value = data.aws_vpc.default.cidr_block
}
output "default_mainrt" {
  value = data.aws_vpc.default.main_route_table_id
}

#create vpc
resource "aws_vpc" "mysql" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

variable "vpc_name" {
  type        = string
  default     = "MySQL-VPC"
  description = "enter vpc name"
}
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/18"
  description = "enter vpc cidr"
}

output "vpc_id" {
  value       = aws_vpc.mysql.id
  description = "id of the mysql vpc "
}



#pub subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.mysql.id
  cidr_block        = var.pub_sub_cidr
  availability_zone = var.az01

  tags = {
    Name = var.pub_sub_name
  }
}
variable "pub_sub_name" {
  type        = string
  default     = "public-sub"
  description = "enter public subnet name"
}
variable "pub_sub_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "enter pubic subnet cidr"
}
variable "az01" {
  type        = string
  default     = "us-east-1a"
  description = "enter the availability zone for public subnet"
}

output "pub_subnet_id" {
  value       = aws_subnet.public-subnet.id
  description = "id of the public subnet "
}


#pvt subnet1
resource "aws_subnet" "pvt-subnet1" {
  vpc_id            = aws_vpc.mysql.id
  cidr_block        = var.pvt_sub1_cidr
  availability_zone = var.az01

  tags = {
    Name = var.pvt_sub_name1
  }
}

variable "pvt_sub_name1" {
  type        = string
  default     = "Database-sub1"
  description = "enter private subnet1 name"
}
variable "pvt_sub1_cidr" {
  type        = string
  default     = "10.0.3.0/24"
  description = "enter private subnet1 cidr"
}

output "pvt_subnet1_id" {
  value       = aws_subnet.pvt-subnet1.id
  description = "id of the public subnet "
}

#pvt subnet2
resource "aws_subnet" "pvt-subnet2" {
  vpc_id            = aws_vpc.mysql.id
  cidr_block        = var.pvt_sub2_cidr
  availability_zone = var.az02

  tags = {
    Name = var.pvt_sub_name2
  }
}
output "pvt_subnet2_id" {
  value       = aws_subnet.pvt-subnet2.id
  description = "id of the public subnet "
}

variable "pvt_sub_name2" {
  type        = string
  default     = "Database-sub2"
  description = "enter private subnet2 name"
}
variable "pvt_sub2_cidr" {
  type        = string
  default     = "10.0.6.0/24"
  description = "enter private subnet2 cidr"
}
variable "az02" {
  type        = string
  default     = "us-east-1b"
  description = "enter the availability zone for private subnet2"
}


#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mysql.id

  tags = {
    Name = "internet-gatewey"
  }
}

#elastic ip
resource "aws_eip" "NAT_eip" {
  #domain = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

#nat gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.NAT_eip.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "NAT-Gatewey"
  }

  depends_on = [aws_internet_gateway.igw]
}

#####route table public
resource "aws_route_table" "pubRT" {
  vpc_id = aws_vpc.mysql.id

  route {
    cidr_block = var.RT-cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = var.vpc_cidr
    gateway_id = var.local_gateway
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.mysql-vpc-peering.id
  }

  tags = {
    Name = "Public-route-table"
  }
  depends_on = [aws_vpc_peering_connection.mysql-vpc-peering]
}
#####route table pvt
resource "aws_route_table" "pvt" {
  vpc_id = aws_vpc.mysql.id

  route {
    cidr_block = var.RT-cidr_block
    gateway_id = aws_nat_gateway.gw.id
  }
  route {
    cidr_block = var.vpc_cidr
    gateway_id = var.local_gateway
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.mysql-vpc-peering.id
  }

  tags = {
    Name = "Public-route-table"
  }
  depends_on = [aws_vpc_peering_connection.mysql-vpc-peering]
}

variable "local_gateway" {
  type        = string
  default     = "local"
  description = "enter local gateway"
}


variable "RT-cidr_block" {
  type        = string
  default     = "0.0.0.0/0"
  description = "enter route table cidr_block"
}

#public subnet association
resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.pubRT.id
}
#pvt subnet association
resource "aws_route_table_association" "pvt-subnet1" {
  subnet_id      = aws_subnet.pvt-subnet1.id
  route_table_id = aws_route_table.pvt.id
}
resource "aws_route_table_association" "pvt-subnet2" {
  subnet_id      = aws_subnet.pvt-subnet2.id
  route_table_id = aws_route_table.pvt.id
}


#vpc peering
resource "aws_vpc_peering_connection" "mysql-vpc-peering" {
  peer_vpc_id = aws_vpc.mysql.id ##our vpc id
  vpc_id      = data.aws_vpc.default.id
  auto_accept = true
}

resource "aws_route" "default_vpc_to_peer" {
  route_table_id            = data.aws_vpc.default.main_route_table_id
  destination_cidr_block    = aws_vpc.mysql.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.mysql-vpc-peering.id
  depends_on                = [aws_vpc_peering_connection.mysql-vpc-peering]
}


#######################################################################
####            security module (security group)
#######################################################################

resource "aws_security_group" "public_sgroups" {
  name   = "public_sg"
  vpc_id = aws_vpc.mysql.id

  dynamic "ingress" {
    for_each = var.public_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.public_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
      description = egress.value.description
    }
  }

  tags = {
    Name = "public-Sgroup"
  }
}
output "pub_SG_id" {
  value       = aws_security_group.public_sgroups.id
  description = "id of the public security group "
}


variable "public_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))

  default = [
    { from_port = 22, to_port = 22, protocol = "tcp", description = "SSH" },
    { from_port = 80, to_port = 80, protocol = "tcp", description = "HTTP" },
    { from_port = 3306, to_port = 3306, protocol = "tcp", description = "MySQL" },
    { from_port = 443, to_port = 443, protocol = "tcp", description = "HTTPS" },
    { from_port = 0, to_port = 0, protocol = "-1", description = "All Inbound" }
  ]
}
variable "public_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))

  default = [
    { from_port = 0, to_port = 0, protocol = "-1", description = "All Inbound" }
  ]
}

###

resource "aws_security_group" "private_sg" {
  name   = "private_sg"
  vpc_id = aws_vpc.mysql.id

  dynamic "ingress" {
    for_each = var.private_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.private_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
      description = egress.value.description
    }
  }

  tags = {
    Name = "private_sg"
  }
}

output "pvt_SG_id" {
  value       = aws_security_group.private_sg.id
  description = "id of the private security group "
}


variable "private_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))

  default = [
    { from_port = 22, to_port = 22, protocol = "tcp", description = "SSH" },
    { from_port = 3306, to_port = 3306, protocol = "tcp", description = "MySQL" },
    { from_port = 80, to_port = 80, protocol = "tcp", description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", description = "HTTPS" },
    { from_port = 0, to_port = 0, protocol = "-1", description = "All Inbound" }
  ]
}
variable "private_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))

  default = [
    { from_port = 0, to_port = 0, protocol = "-1", description = "All Inbound" }
  ]
}


#######################################################################
####            Nacl
#######################################################################

resource "aws_network_acl" "naclpvt" {
  vpc_id = aws_vpc.mysql.id

  # Egress rule using the variable
  egress {
    protocol   = var.egress_rule.protocol
    rule_no    = var.egress_rule.rule_no
    action     = var.egress_rule.action
    cidr_block = var.egress_rule.cidr_block
    from_port  = var.egress_rule.from_port
    to_port    = var.egress_rule.to_port
  }

  # Ingress rule using the variable
  ingress {
    protocol   = var.ingress_rule.protocol
    rule_no    = var.ingress_rule.rule_no
    action     = var.ingress_rule.action
    cidr_block = var.ingress_rule.cidr_block
    from_port  = var.ingress_rule.from_port
    to_port    = var.ingress_rule.to_port
  }

  tags = {
    Name = "pvt-nacl"
  }
}


#######################

variable "egress_rule" {
  description = "Egress rule configuration"
  type = object({
    protocol   = string
    rule_no    = number
    action     = string
    cidr_block = string
    from_port  = number
    to_port    = number
  })
  default = {
    protocol   = "all"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

variable "ingress_rule" {
  description = "ingress rule configuration"
  type = object({
    protocol   = string
    rule_no    = number
    action     = string
    cidr_block = string
    from_port  = number
    to_port    = number
  })
  default = {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

output "pvt_NACL_id" {
  value       = aws_network_acl.naclpvt.id
  description = "id of the private NACL"
}


###### nacl association pvt1
resource "aws_network_acl_association" "pvt1" {
  network_acl_id = aws_network_acl.naclpvt.id
  subnet_id      = aws_subnet.pvt-subnet1.id
}

###### nacl association pvt2
resource "aws_network_acl_association" "pv2" {
  network_acl_id = aws_network_acl.naclpvt.id
  subnet_id      = aws_subnet.pvt-subnet2.id
}

#######################################################################
####            compute module (instance)
#######################################################################

resource "aws_instance" "public-instance" {
  ami                         = var.ami_id
  instance_type               = var.pub_ec2_type
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = var.key
  associate_public_ip_address = var.assign_public_IP_pub
  security_groups             = [aws_security_group.public_sgroups.id]
  root_block_device {
    volume_size = var.volume_size
  }

  tags = {
    Name = var.pub_instance
    DB   = var.tag_name
  }
}

resource "aws_instance" "private-instance1" {
  ami                         = var.ami_id
  instance_type               = var.pvt_ec2_type
  subnet_id                   = aws_subnet.pvt-subnet1.id
  key_name                    = var.key
  associate_public_ip_address = var.assign_public_IP_pvt
  security_groups             = [aws_security_group.private_sg.id]
  root_block_device {
    volume_size = var.volume_size
  }

  tags = {
    Name = var.pvt_instance1
    DB   = var.tag_name
  }
}
resource "aws_instance" "private-instance2" {
  ami                         = var.ami_id
  instance_type               = var.pvt_ec2_type
  subnet_id                   = aws_subnet.pvt-subnet2.id
  key_name                    = var.key
  associate_public_ip_address = var.assign_public_IP_pvt
  security_groups             = [aws_security_group.private_sg.id]
  root_block_device {
    volume_size = var.volume_size
  }

  tags = {
    Name = var.pvt_instance2
  }
}

variable "pub_instance" {
  type        = string
  default     = "Bastion_host"
  description = "enter public instance name"
}
variable "tag_name" {
  type        = string
  default     = "mysql"
  description = "enter tag name of instance"
}
variable "pvt_instance1" {
  type        = string
  default     = "Database-server1"
  description = "enter Database server1 instance name"
}
variable "pvt_instance2" {
  type        = string
  default     = "Database-server2"
  description = "enter Database server2 instance name"
}
variable "ami_id" {
  type        = string
  default     = "ami-0e2c8caa4b6378d8c"
  description = "AMI ID of instanace"
}
variable "key" {
  type        = string
  default     = "nvirinia"
  description = "enter pem key name"
}
variable "pub_ec2_type" {
  type        = string
  default     = "t2.micro"
  description = "enter instance types"
}
variable "pvt_ec2_type" {
  type        = string
  default     = "t2.micro"
  description = "enter instance types"
}
variable "assign_public_IP_pub" {
  type        = bool
  default     = true
  description = "assign_public_IP for private"
}
variable "assign_public_IP_pvt" {
  type        = bool
  default     = false
  description = "assign_public_IP for private"
}
variable "volume_size" {
  type        = number
  default     = 29
  description = "root volume size for the EC2 instances"
}

output "pub_instance_id" {
  value       = aws_instance.public-instance.id
  description = "id of the public instance "
}
output "pvt_instance1_id" {
  value       = aws_instance.private-instance1.id
  description = "id of the private instance1 "
}
output "pvt_instance2_id" {
  value       = aws_instance.private-instance2.id
  description = "id of the private instance2"
}
output "Bastion_Public_IP" {
  value       = aws_instance.public-instance.public_ip
  description = "Public IP address of the bastion EC2 instance"
}


#######################################################################
####            compute module (target group)
#######################################################################

resource "aws_lb_target_group" "target" {
  name     = var.tg_name
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = aws_vpc.mysql.id
  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_threshold
    unhealthy_threshold = var.unhealth_check_threshold
    matcher             = var.health_check_matcher
  }
}
variable "tg_name" {
  type        = string
  default     = "Mysql-target"
  description = "target group name"
}
variable "tg_port" {
  type        = number
  default     = 80
  description = "target group port"
}
variable "tg_protocol" {
  type        = string
  default     = "HTTP"
  description = "type of Target protocol"
}
variable "health_check_path" {
  type        = string
  default     = "/"
  description = "enter health check path"
}
variable "health_check_interval" {
  type        = number
  default     = 280
  description = "enter health check interval"
}
variable "health_check_timeout" {
  type        = number
  default     = 5
  description = "enter health check timeout"
}
variable "health_check_threshold" {
  type        = number
  default     = 2
  description = "enter health check healthy threshold"
}
variable "unhealth_check_threshold" {
  type        = number
  default     = 10
  description = "enter health check unhealthy threshold"
}
variable "health_check_matcher" {
  type        = string
  default     = "200-299"
  description = "enter health check matcher"
}


resource "aws_lb_target_group_attachment" "tg_attachment_private_instance1" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_instance.private-instance1.id
  port             = var.tg_attachment_port
}

resource "aws_lb_target_group_attachment" "tg_attachment_private_instance2" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_instance.private-instance2.id
  port             = var.tg_attachment_port
}

variable "tg_attachment_port" {
  type        = number
  default     = 80
  description = "target group attachment port"
}

# ########################################################################################
# ##  Auto Load Balancer
# #######################################################################################

resource "aws_lb" "MySQL-alb" {
  name               = var.lb_name
  internal           = var.lb_internal
  load_balancer_type = var.lb_tpye
  security_groups = [
    aws_security_group.private_sg.id
  ]
  subnets = [
    aws_subnet.public-subnet.id,
    aws_subnet.pvt-subnet2.id
  ]

  enable_deletion_protection = false
}
variable "lb_name" {
  type        = string
  default     = "mysql-LB"
  description = "enter load balancer name"
}
variable "lb_internal" {
  type        = bool
  default     = false
  description = "enter load balancer internal"
}
variable "lb_tpye" {
  type        = string
  default     = "application"
  description = "enter load balancer type"
}

variable "lb_enable_deletion" {
  type        = bool
  default     = false
  description = "enter load balancer enable deletion protection"
}


# ##################################################################################
# ##  Auto Load Balancer listner
# ##################################################################################

resource "aws_lb_listener" "mysql_alb_listener" {
  load_balancer_arn = aws_lb.MySQL-alb.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    type             = var.alb_listener_action
    target_group_arn = aws_lb_target_group.target.arn
  }
}
variable "alb_listener_port" {
  type        = number
  default     = 80
  description = " alb listener port"
}
variable "alb_listener_protocol" {
  type        = string
  default     = "HTTP"
  description = "type of Target protocol"
}
variable "alb_listener_action" {
  type        = string
  default     = "forward"
  description = "type of Target protocol"
}

output "load_balancer_DNS" {
  value       = aws_lb.MySQL-alb.dns_name
  description = "DNS name of load balancer"
}
