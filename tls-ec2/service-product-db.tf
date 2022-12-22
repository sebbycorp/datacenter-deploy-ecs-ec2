locals {
  product_api-db_name = "product-api-db"
  product_api-db_port = 5432
}

resource "aws_ecs_service" "product-api-db" {
  name            = local.product_api-db_name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.product-api-db.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
    # assign_public_ip = true
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.public-api-db.arn
  #   container_name   = local.public_api-db_name
  #   container_port   = local.public_api-db_port
  # }
  enable_execute_command = true
}

module "product-api-db" {
  source           = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version          = "0.5.2"
  family            = local.product_api-db_name
  cpu               = 1024
  memory            = 2048
  port              = local.product_api-db_port
  log_configuration = local.product-api-db_log_config
  container_definitions = [{
    name             = local.product_api-db_name
    image            = "hashicorpdemoapp/product-api-db:latest"
    essential        = true
    logConfiguration = local.product-api-db_log_config
    environment = [
      {
        name  = "POSTGRES_DB"
        value = "products"
      },
      {
        name  = "POSTGRES_USER"
        value = "postgres"
      }
    ]
    linuxParameters = {
      initProcessEnabled = true
    }
    portMappings = [
      {
        containerPort = local.product_api-db_port
        hostPort      = local.product_api-db_port
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