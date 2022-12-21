# The client app is part of the service mesh. It calls
# the server app through the service mesh.
# It's exposed via a load balancer.
resource "aws_ecs_service" "fargate_client_app" {
  name            = "${var.name}-fargate-client-app"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.fargate_client_app.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_client_app.arn
    container_name   = "fargate-client-app"
    container_port   = 9090
  }
  enable_execute_command = true
}

# The server app is part of the service mesh. It's called
# by the client app.
resource "aws_ecs_service" "fargate_server_app" {
  name            = "${var.name}-fargate-server-app"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.fargate_server_app.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}