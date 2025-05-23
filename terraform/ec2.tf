# Create IAM role for EC2
resource "aws_iam_role" "ec2_role" {
  provider = aws.primary
  name     = "${var.project_name}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  provider = aws.primary
  name     = "${var.project_name}-ec2-profile"
  role     = aws_iam_role.ec2_role.name
}

# Attach S3 access policy to role
resource "aws_iam_role_policy" "s3_access" {
  provider = aws.primary
  name     = "${var.project_name}-s3-access"
  role     = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.primary.arn,
          "${aws_s3_bucket.primary.arn}/*",
          aws_s3_bucket.secondary.arn,
          "${aws_s3_bucket.secondary.arn}/*"
        ]
      }
    ]
  })
}

# Primary EC2 Instance
resource "aws_instance" "primary" {
  provider                    = aws.primary
  count                       = 2  # Creating 2 instances for high availability
  ami                         = var.ami_primary
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.primary_public[count.index % length(aws_subnet.primary_public)].id
  vpc_security_group_ids      = [aws_security_group.primary_web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd awslogs

    # Start and enable Apache
    systemctl start httpd
    systemctl enable httpd

    # Configure the CloudWatch Logs agent
    cat > /etc/awslogs/awslogs.conf <<CWCONF
    [general]
    state_file = /var/lib/awslogs/agent-state

    [/var/log/messages]
    file = /var/log/messages
    log_group_name = /aws/ec2/jenkins
    log_stream_name = {instance_id}/messages
    datetime_format = %b %d %H:%M:%S
    CWCONF

    # Start and enable CloudWatch Logs agent
    systemctl start awslogsd
    systemctl enable awslogsd.service

    # Simple web page
    echo "<h1>This is the primary region server ${count.index + 1}</h1>" > /var/www/html/index.html
    EOF

  
  tags = {
    Name = "${var.project_name}-primary-ec2-${count.index + 1}"
  }
}

# Secondary EC2 Instance
resource "aws_instance" "secondary" {
  provider                    = aws.secondary
  count                       = 2  # Creating 2 instances for high availability
  ami                         = var.ami_secondary
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.secondary_public[count.index % length(aws_subnet.secondary_public)].id
  vpc_security_group_ids      = [aws_security_group.secondary_web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd awslogs

    # Start and enable Apache
    systemctl start httpd
    systemctl enable httpd

    # Configure the CloudWatch Logs agent
    cat > /etc/awslogs/awslogs.conf <<CWCONF
    [general]
    state_file = /var/lib/awslogs/agent-state

    [/var/log/messages]
    file = /var/log/messages
    log_group_name = /aws/ec2/jenkins
    log_stream_name = {instance_id}/messages
    datetime_format = %b %d %H:%M:%S
    CWCONF

    # Start and enable CloudWatch Logs agent
    systemctl start awslogsd
    systemctl enable awslogsd.service

    # Simple web page
    echo "<h1>This is the secondary region (DR) server ${count.index + 1}</h1>" > /var/www/html/index.html
    EOF
  
  tags = {
    Name = "${var.project_name}-secondary-ec2-${count.index + 1}"
  }
}

# Application Load Balancer - Primary Region
resource "aws_lb" "primary" {
  provider           = aws.primary
  name               = "${var.project_name}-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_web.id]
  subnets            = aws_subnet.primary_public[*].id
  
  tags = {
    Name = "${var.project_name}-primary-alb"
  }
}

resource "aws_lb_target_group" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "instance"
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "primary" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

resource "aws_lb_target_group_attachment" "primary" {
  provider         = aws.primary
  count            = length(aws_instance.primary)
  target_group_arn = aws_lb_target_group.primary.arn
  target_id        = aws_instance.primary[count.index].id
  port             = 80
}

# Application Load Balancer - Secondary Region
resource "aws_lb" "secondary" {
  provider           = aws.secondary
  name               = "${var.project_name}-secondary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_web.id]
  subnets            = aws_subnet.secondary_public[*].id
  
  tags = {
    Name = "${var.project_name}-secondary-alb"
  }
}

resource "aws_lb_target_group" "secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secondary.id
  target_type = "instance"
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "secondary" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary.arn
  }
}

resource "aws_lb_target_group_attachment" "secondary" {
  provider         = aws.secondary
  count            = length(aws_instance.secondary)
  target_group_arn = aws_lb_target_group.secondary.arn
  target_id        = aws_instance.secondary[count.index].id
  port             = 80
}
