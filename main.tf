# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "aws-webapp-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "aws-webapp-gateway"
  }
}

# Subnet's for Public and Private instances
resource "aws_subnet" "public-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = {
    Name = "aws-webapp-public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  map_public_ip_on_launch = true
  tags = {
    Name = "aws-webapp-public-2"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = {
    Name = "aws-webapp-private-1"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_2
  map_public_ip_on_launch = true
  tags = {
    Name = "aws-webapp-private-2"
  }
}

# Network Gateway
resource "aws_eip" "eip-1" {
  domain = "vpc"
  tags = {
    Name = "aws-webapp-eip-1"
  }
}

resource "aws_eip" "eip-2" {
  domain = "vpc"
  tags = {
    Name = "aws-webapp-eip-2"
  }
}

resource "aws_nat_gateway" "nat-1" {
  allocation_id = aws_eip.eip-1.id
  subnet_id     = aws_subnet.public-1.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "aws-webapp-nat-gateway-1"
  }
}

resource "aws_nat_gateway" "nat-2" {
  allocation_id = aws_eip.eip-2.id
  subnet_id     = aws_subnet.public-2.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "aws-webapp-nat-gateway-2"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "aws-webapp-public-route"
  }
}

resource "aws_route_table_association" "public-1-association" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2-association" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables
resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-1.id
  }
  tags = {
    Name = "aws-webapp-private-route-1"
  }
}

resource "aws_route_table" "private-2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-2.id
  }
  tags = {
    Name = "aws-webapp-private-route-2"
  }
}

resource "aws_route_table_association" "private-1-association" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route_table_association" "private-2-association" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private-2.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "aws-webapp-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "aws-webapp-alb-sg"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "aws-webapp-app-sg"
  description = "Application instances security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-webapp-app-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "aws-webapp-db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-webapp-db-sg"
  }
}


resource "aws_security_group_rule" "alb_to_app" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to access app instances on port 80"
}

resource "aws_security_group_rule" "app_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "Allow app instances to access database on port 5432"
}



# ALB + Target Group + Listner
resource "aws_lb" "app_alb" {
  name               = "aws-webapp-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public-1.id, aws_subnet.public-2.id]


  tags = {
    Name = "aws-webapp-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "aws-webapp-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = { Name = "aws-webapp-tg" }
}

resource "aws_lb_listener" "http_or_https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  dynamic "default_action" {
    for_each = [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app_tg.arn
    }
  }
}


# IAM Role for EC2
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "aws-webapp-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "aws-webapp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Template 
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y nginx

    cat >/usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>🚀 AWS WebApp</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #00c6ff, #0072ff);
          color: #fff;
          text-align: center;
          margin: 0;
          height: 100vh;
          display: flex;
          flex-direction: column;
          justify-content: center;
        }
        h1 {
          font-size: 3em;
          margin-bottom: 10px;
          text-shadow: 2px 2px 6px rgba(0,0,0,0.3);
        }
        p {
          font-size: 1.2em;
        }
        .card {
          background: rgba(255, 255, 255, 0.1);
          padding: 30px;
          border-radius: 15px;
          backdrop-filter: blur(8px);
          display: inline-block;
        }
        footer {
          position: absolute;
          bottom: 15px;
          width: 100%;
          font-size: 0.9em;
          opacity: 0.8;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1> AWS WebApp — It Works!</h1>
        <p> Your application is running on Amazon EC2</p>
        <p>🔗 DB endpoint: <strong>${aws_db_instance.app_db.address}</strong></p>
      </div>
      <footer>Built with 💙 using Terraform, EC2, and NGINX</footer>
    </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl start nginx
  EOT
}


resource "aws_launch_template" "app_lt" {
  name_prefix   = "aws-webapp-lt"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = base64encode(local.user_data)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 16
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "aws-webapp-app" }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "aws-webapp-asg"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "aws-webapp-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "aws-webapp-cpu50"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

# RDS - PostgreSQL
resource "aws_db_subnet_group" "db_subnets" {
  name       = "aws-webapp-db-subnets"
  subnet_ids = [aws_subnet.private-1.id, aws_subnet.private-2.id]
}

resource "aws_db_instance" "app_db" {
  identifier                 = "aws-webapp-db"
  engine                     = "postgres"
  engine_version             = "17"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  db_subnet_group_name       = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids     = [aws_security_group.db_sg.id]
  username                   = ""
  password                   = ""
  publicly_accessible        = false
  skip_final_snapshot        = true
  backup_retention_period    = 7
  deletion_protection        = false
  multi_az                   = false
  storage_encrypted          = true
  apply_immediately          = true
  auto_minor_version_upgrade = true
}
