resource "aws_lb" "hashicups" {
  name               = "hashicups"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend.id]
  subnets            = module.vpc.public_subnets
}


## HashiCups Frontend

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.hashicups.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_target_group" "frontend" {
  name                 = "frontend"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
  }
}


## HashiCups Public API

resource "aws_lb_listener" "public-api" {
  load_balancer_arn = aws_lb.hashicups.arn
  port              = 8081
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public-api.arn
  }
}

resource "aws_lb_target_group" "public-api" {
  name                 = "public-api"
  port                 = 8081
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
  }
}