resource "aws_instance" "consul-client" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.consul.id]
  user_data              = templatefile("./scripts/consul-client-init.sh", {
    consul_datacenter = var.consul_datacenter
    consul_acl_token  = random_uuid.bootstrap_token.result
    consul_gossip_key = random_id.gossip_encryption_key.b64_std
    consul_ca_cert    = tls_self_signed_cert.ca.cert_pem
    consul_ca_key     = tls_private_key.ca.private_key_pem
    consul_version    = var.consul_version
  })
  iam_instance_profile   = aws_iam_instance_profile.consul.name
  key_name               = var.ssh_keypair_name
  tags = {
    Name = "${var.name}-consul-server"
    Env  = "consul"
  }
}