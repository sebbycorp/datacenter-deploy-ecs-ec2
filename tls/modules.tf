module "acl_controller" {
  source     = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version    = "0.5.2"
  depends_on = [aws_instance.consul]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  consul_server_ca_cert_arn         = aws_secretsmanager_secret.ca_cert.arn
  consul_server_http_addr           = "https://${aws_instance.consul.private_ip}:8501"
  ecs_cluster_arn                   = aws_ecs_cluster.this.arn
  region                            = var.region
  subnets                           = module.vpc.private_subnets
  name_prefix                       = var.name
}


module "example_client_app" {
  source            = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version           = "0.5.2"
  family            = "${var.name}-example-client-app"
  requires_compatibilities = ["EC2"]
  memory                   = 256
  port              = "9090"
  log_configuration = local.example_client_app_log_config
  container_definitions = [{
    name             = "example-client-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-client-app"
      },
      {
        name  = "UPSTREAM_URIS"
        value = "http://localhost:1234"
      }
    ]
    portMappings = [
      {
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
      }
    ]
    cpu         = 0
    mountPoints = []
    volumesFrom = []
  }]
  upstreams = [
    {
      destinationName = "${var.name}-example-server-app"
      localBindPort  = 1234
    }
  ]
  retry_join                     = [aws_instance.consul.private_ip]
  tls                            = true
  consul_server_ca_cert_arn      = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn          = aws_secretsmanager_secret.gossip_key.arn
  consul_https_ca_cert_arn     = aws_secretsmanager_secret.ca_cert.arn
  acls                           = true
  consul_datacenter              = var.consul_datacenter
  consul_http_addr        = "https://${aws_instance.consul.private_ip}:8501"

  depends_on = [module.acl_controller, module.example_server_app]
}

module "example_server_app" {
  source            = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version           = "0.5.2"
  family            = "${var.name}-example-server-app"
  requires_compatibilities = ["EC2"]
  memory                   = 256
  port              = "9090"
  log_configuration = local.example_server_app_log_config
  container_definitions = [{
    name             = "example-server-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_server_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-server-app"
      }
    ]
  }]
  retry_join                     = [aws_instance.consul.private_ip]
  tls                            = true
  consul_server_ca_cert_arn      = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn          = aws_secretsmanager_secret.gossip_key.arn
  acls                           = true
  consul_https_ca_cert_arn     = aws_secretsmanager_secret.ca_cert.arn
  consul_datacenter              = var.consul_datacenter
  consul_http_addr        = "https://${aws_instance.consul.private_ip}:8501"
  depends_on = [module.acl_controller]
}