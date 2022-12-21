resource "aws_lb" "consul" {
  name               = "${var.name}-consul"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.consul.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "consul" {
  name                 = "${var.name}-consul"
  port                 = 8500
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 10
  health_check {
    path                = "/v1/status/leader"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
  }
}

resource "aws_lb_listener" "consul" {
  load_balancer_arn = aws_lb.consul.arn
  port              = "8500"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.consul.arn
  }
}

resource "aws_lb_target_group_attachment" "consul" {
  target_group_arn = aws_lb_target_group.consul.arn
  target_id        = aws_instance.consul.id
}


###
resource "aws_lb" "example_client_app" {
  name               = "${var.name}-example-client-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_client_app_alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "example_client_app" {
  name                 = "${var.name}-example-client-app"
  port                 = 9090
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
  }
}

resource "aws_lb_listener" "example_client_app" {
  load_balancer_arn = aws_lb.example_client_app.arn
  port              = "9090"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_client_app.arn
  }
}