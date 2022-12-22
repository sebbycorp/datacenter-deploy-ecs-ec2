locals {
  frontend_name = "frontend"
  frontend_port = 3000
}




resource "aws_ecs_service" "frontend" {
  name            = local.frontend_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.frontend.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
    assign_public_ip = true
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = local.frontend_name
    container_port   = local.frontend_port
  }
  enable_execute_command = true
}

module "frontend" {
  source           = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version          = "0.5.2"
  family            = local.frontend_name
  cpu               = 1024
  memory            = 2048
  port              = "3000"
  log_configuration = local.frontend_log_config
  container_definitions = [{
    name             = local.frontend_name
    image            = "hashicorpdemoapp/frontend:latest"
    essential        = true
    logConfiguration = local.frontend_log_config
    environment = [{
      name  = "NAME"
      value = local.frontend_name
      },
      {
        name = "NEXT_PUBLIC_PUBLIC_API_URL",
        value = "http://${aws_lb.hashicups.dns_name}:8081"
      }
    ]
    linuxParameters = {
      initProcessEnabled = true
    }
    portMappings = [
      {
        containerPort = local.frontend_port
        hostPort      = local.frontend_port
        protocol      = "tcp"
      }
    ]
    cpu         = 0
    mountPoints = []
    volumesFrom = []
  }]
  upstreams = [
    {
      destinationName = "public-api"
      localBindPort   = 8081
    }
  ]
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