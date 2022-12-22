locals {
  payments_name = "payments"
  payments_port = 8080
}

resource "aws_ecs_service" "payments" {
  name            = local.payments_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.payments.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
    # assign_public_ip = true
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.public-api.arn
  #   container_name   = local.public_api_name
  #   container_port   = local.public_api_port
  # }
  enable_execute_command = true
}

module "payments" {
  source           = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version          = "0.5.2"
  family            = local.payments_name
  cpu               = 1024
  memory            = 2048
  port              = local.payments_port
  log_configuration = local.payments_log_config
  container_definitions = [{
    name             = local.payments_name
    image            = "hashicorpdemoapp/payments:latest"
    essential        = true
    logConfiguration = local.payments_log_config
    environment = [

    ]
    linuxParameters = {
      initProcessEnabled = true
    }
    portMappings = [
      {
        containerPort = local.payments_port
        hostPort      = local.payments_port
        protocol      = "tcp"
      }
    ]

  }]
  upstreams = [

  ]
  // Strip away the https prefix from the Consul network address
  retry_join                     = [aws_instance.consul.private_ip]
  tls                            = true
  consul_server_ca_cert_arn      = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn          = aws_secretsmanager_secret.gossip_key.arn
  acls                           = true
  consul_https_ca_cert_arn     = aws_secretsmanager_secret.ca_cert.arn
  consul_datacenter              = var.consul_datacenter
  consul_http_addr        = "https://${aws_instance.consul.private_ip}:8501"
  additional_task_role_policies = [aws_iam_policy.execute_command.arn]
  depends_on                    = [module.acl_controller]
}