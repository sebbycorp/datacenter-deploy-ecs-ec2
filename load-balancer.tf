resource "aws_lb" "example_client_app" {
  name               = "${var.name}-client-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_client_app_alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "example_client_app" {
  name                 = "${var.name}-client-app"
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