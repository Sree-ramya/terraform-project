terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-project-bucket-july"
    key    = "terraform-infra-file.tf"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}


# creating the vpc resource 

resource "aws_vpc" "Mumbai-VPC" {
  cidr_block       = "10.10.0.0/16"

  tags = {
    Name = "Mumbai-VPC"
  }
}

# creating subnet resources

resource "aws_subnet" "Mumbai-subnet-1a" {
  vpc_id     = aws_vpc.Mumbai-VPC.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Mumbai-subnet-1a"
  }
}

resource "aws_subnet" "Mumbai-subnet-1b" {
  vpc_id     = aws_vpc.Mumbai-VPC.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Mumbai-subnet-1b"
  }
}

resource "aws_subnet" "Mumbai-subnet-1c" {
  vpc_id     = aws_vpc.Mumbai-VPC.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Mumbai-subnet-1c"
  }
}

# creating ec2 instances

resource "aws_instance" "Mumbai-instance" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name = aws_key_pair.mumbai-key-pair.id
  subnet_id = aws_subnet.Mumbai-subnet-1a.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.mumbai_SG_ssh_http.id]

  tags = {
    Name = "Mumbai-instance-pro"
  }
}

resource "aws_instance" "Mumbai-instance-1" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name = aws_key_pair.mumbai-key-pair.id
  subnet_id = aws_subnet.Mumbai-subnet-1b.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.mumbai_SG_ssh_http.id]

  tags = {
    Name = "Mumbai-instance-pro-1"
  }
}


# creating key-pair resource

resource "aws_key_pair" "mumbai-key-pair" {
  key_name   = "july-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDinjD7fsQSip4YgzZp/Dst4/Bv9weXxK7v/VZen2yzYFg734/kyjylQk/KfIBQG00jHOjeoHYoFW77KiMvSea9y06kKqIiMcVoZlu+TCo+5GRbw0eFALPVIDQ6tlS0zEUv27gHM39cnIiYP3J2lOENyk5SqQPPY5iDb48CNRvPR9mHxCdw6RGGYZQKwQFqrB25CoE4f/vcXk9kJg+O29sHvm1uU7MqF2rKAGANCRf4pcTjo59dW3bCtLb5wXWltQBbeuE226hb7cRfB8qo0hI3G1q8+Wp8GAZjgBbge5X0rTCsiTiGoLIG7gLga8gqdohXtuqORQ9InZr7AFk/eTwhwJsAG+2HfxhhnV4d1gMOck0dprLm0MyPidUO65CmSpug3OvugPmbJkikzI3ieifAy64VBBZXYpYX4jkfK4zqnkoAYcRl2yPdd/o6RnoSV3W6FMl56YpHdv5rcqhkYdVInomSV/smz6XvhcYwK+pFJWDdpzU3sGyhwi4AT/eWn/0= ksree@LAPTOP-O0D3TLAS"
}

# creating security-group resources

resource "aws_security_group" "mumbai_SG_ssh_http" {
  name        = "mumbai_SG_ssh_http"
  description = "Allow ssh_http inbound traffic"
  vpc_id      = aws_vpc.Mumbai-VPC.id

  ingress {
    description      = "SSH from PC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from PC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  tags = {
    Name = "mumbai_SG_ssh_http"
  }
}

# creating internet gateway

resource "aws_internet_gateway" "mumbai-Igw" {
  vpc_id = aws_vpc.Mumbai-VPC.id

  tags = {
    Name = "mumbai-igw"
  }
}

# creating Route table

resource "aws_route_table" "mumbai-RT" {
  vpc_id = aws_vpc.Mumbai-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai-Igw.id
  }

  tags = {
    Name = "mumbai-RT"
  }
}

resource "aws_route_table_association" "mumbai-RT-associaciation-1" {
  subnet_id      = aws_subnet.Mumbai-subnet-1a.id
  route_table_id = aws_route_table.mumbai-RT.id
}


resource "aws_route_table_association" "mumbai-RT-associaciation-2" {
  subnet_id      = aws_subnet.Mumbai-subnet-1b.id
  route_table_id = aws_route_table.mumbai-RT.id
}

# creating Target group

resource "aws_lb_target_group" "Mumbai-TG" {
  name     = "mumbai-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Mumbai-VPC.id
}

resource "aws_lb_target_group_attachment" "mumbai-TG-attachment-1" {
  target_group_arn = aws_lb_target_group.Mumbai-TG.arn
  target_id        = aws_instance.Mumbai-instance.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "mumbai-TG-attachment-2" {
  target_group_arn = aws_lb_target_group.Mumbai-TG.id
  target_id        = aws_instance.Mumbai-instance-1.id
  port             = 80
}

# creating load balancer listener

resource "aws_lb_listener" "mumbai-listener" {
  load_balancer_arn = aws_lb.mumbai-LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Mumbai-TG.arn
  }
}

# creating load balancer

resource "aws_lb" "mumbai-LB" {
  name               = "cardwebsite-mumbai-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mumbai_SG_ssh_http.id]
  subnets            = [aws_subnet.Mumbai-subnet-1a.id, aws_subnet.Mumbai-subnet-1b.id]

  tags = {
    Environment = "production"
  }
}

# creating launch template 

resource "aws_launch_template" "mumbai_launch_template" {
  name = "Mumbai_launch_template"

  image_id = "ami-0f5ee92e2d63afc18"
 
  instance_type = "t2.micro"

  key_name = aws_key_pair.mumbai-key-pair.id

  monitoring {
    enabled = true
  }

  placement {
    availability_zone = "us-west-2a"
  }

  vpc_security_group_ids = [aws_security_group.mumbai_SG_ssh_http.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Mumbai-instance-ASG"
    }
  }

  user_data = filebase64("userdata.sh")
}

resource "aws_autoscaling_group" "mumbai-ASG" {
  vpc_zone_identifier = [aws_subnet.Mumbai-subnet-1a.id, aws_subnet.Mumbai-subnet-1b.id]
  
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  
  launch_template {
    id      = aws_launch_template.mumbai_launch_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.mumbai-TG-1.arn]
}

# ALB TG with ASG

resource "aws_lb_target_group" "mumbai-TG-1" {
  name     = "Mumbai-TG-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Mumbai-VPC.id
}

# LB Listener with ASG

resource "aws_lb_listener" "mumbai-listener-1" {
  load_balancer_arn = aws_lb.mumbai-LB-1.arn
  port              = "80"
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-TG-1.arn
  }
}


#load balancer with ASG

resource "aws_lb" "mumbai-LB-1" {
  name               = "Mumbai-LB-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mumbai_SG_ssh_http.id]
  subnets            = [aws_subnet.Mumbai-subnet-1a.id, aws_subnet.Mumbai-subnet-1b.id]


  tags = {
    Environment = "production"
  }
}