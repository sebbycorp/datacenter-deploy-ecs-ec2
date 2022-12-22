resource "aws_security_group" "frontend" {
  name   = "frontend-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access to frontend Web UI."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to GraphQL API."
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to frontend Web UI."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Access to GraphQL API."
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress_from_client_h_alb_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = data.aws_security_group.vpc_default.id
}

