
module "fargate_client_app" {
  source            = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version           = "0.5.2"
  family            = "${var.name}-fargate-client-app"
  port              = "9090"
  log_configuration = local.fargate_client_app_log_config
  container_definitions = [{
    name             = "fargate-client-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.fargate_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-fargate-client-app"
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
      destinationName = "${var.name}-fargate-server-app"
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

  depends_on = [module.acl_controller, module.fargate_server_app]
}

module "fargate_server_app" {
  source            = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version           = "0.5.2"
  family            = "${var.name}-fargate-server-app"
  port              = "9090"
  log_configuration = local.fargate_server_app_log_config
  container_definitions = [{
    name             = "fargate-server-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.fargate_server_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-fargate-server-app"
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