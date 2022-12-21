

###
resource "aws_lb" "fargate_client_app" {
  name               = "${var.name}-fargate-client-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fargate_client_app_alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "fargate_client_app" {
  name                 = "${var.name}-fargate-client-app"
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

resource "aws_lb_listener" "fargate_client_app" {
  load_balancer_arn = aws_lb.fargate_client_app.arn
  port              = "9090"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_client_app.arn
  }
}