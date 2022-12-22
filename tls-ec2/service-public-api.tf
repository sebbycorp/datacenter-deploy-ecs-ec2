locals {
  public_api_name = "public-api"
  public_api_port = 8081
}

resource "aws_ecs_service" "public-api" {
  name            = local.public_api_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.public-api.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
    assign_public_ip = true
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.public-api.arn
    container_name   = local.public_api_name
    container_port   = local.public_api_port
  }
  enable_execute_command = true
}

module "public-api" {
  source           = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version          = "0.5.2"
  family            = local.public_api_name
  cpu               = 1024
  memory            = 2048
  port              = local.public_api_port
  log_configuration = local.public-api_log_config
  container_definitions = [{
    name             = local.public_api_name
    image            = "hashicorpdemoapp/public-api:latest"
    essential        = true
    logConfiguration = local.public-api_log_config
    environment = [
      {
        name  = "PAYMENT_API_URI"
        value = "http://localhost:8080"
      },
      {
        name  = "PRODUCT_API_URI"
        value = "http://localhost:9091"
      },
      {
        name  = "BIND_ADDRESS"
        value = ":${local.public_api_port}"
      }
    ]
    linuxParameters = {
      initProcessEnabled = true
    }
    portMappings = [
      {
        containerPort = local.public_api_port
        hostPort      = local.public_api_port
        protocol      = "tcp"
      }
    ]

  }]
  upstreams = [
    {
      destinationName      = "product-api"
      localBindPort        = 9091
    },
    {
      destinationName      = "payments"
      localBindPort        = 8080

    }
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