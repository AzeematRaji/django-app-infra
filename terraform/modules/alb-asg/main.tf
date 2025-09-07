data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch Template
resource "aws_launch_template" "django_app" {
  name_prefix   = "django-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [var.ec2_security_group_id]
  
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }
  
  user_data = base64encode(templatefile("${path.root}/userdata/django-app-setup.sh", {
    rds_endpoint   = var.rds_endpoint
    db_name        = var.db_name
    db_username    = var.db_username
    db_password    = var.db_password
    s3_bucket_name = var.s3_bucket_name
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "django-app-instance"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "django-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets           = var.public_subnet_ids
  
  enable_deletion_protection = false
  
  tags = var.tags
}

# Target Group
resource "aws_lb_target_group" "django_app" {
  name     = "django-app-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = var.tags
}

# Load Balancer Listener
resource "aws_lb_listener" "django_app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django_app.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "django_app" {
  name                = "django-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.django_app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.django_app.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "django-app-asg"
    propagate_at_launch = false
  }
  
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "django-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.django_app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "django-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.django_app.name
}