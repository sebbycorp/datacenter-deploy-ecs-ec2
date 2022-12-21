resource "aws_instance" "ec2-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.consul.id]

  user_data              = templatefile("./scripts/consul-client-init.sh", {
    consul_datacenter = var.consul_datacenter
    consul_gossip_key = random_id.gossip_encryption_key.b64_std
    consul_version    = var.consul_version
    vpc_cidr = module.vpc.vpc_cidr_block
    consul_ip = aws_instance.consul.private_ip
  })
  iam_instance_profile   = aws_iam_instance_profile.consul.name
  key_name               = aws_key_pair.webssh.key_name
  tags = {
    Name = "${var.name}-ec2-server"
    Env  = "consul"
  }
}

resource "aws_instance" "ec2-app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.consul.id]
  user_data              = templatefile("./scripts/consul-client-app.sh", {
    consul_datacenter = var.consul_datacenter
    consul_gossip_key = random_id.gossip_encryption_key.b64_std
    consul_version    = var.consul_version
    vpc_cidr = module.vpc.vpc_cidr_block
    consul_ip = aws_instance.consul.private_ip
  })
  iam_instance_profile   = aws_iam_instance_profile.consul.name
  key_name               = aws_key_pair.webssh.key_name
  tags = {
    Name = "${var.name}-ec2-app"
    Env  = "consul"
  }
}



resource "tls_private_key" "webssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "webssh" {
  public_key = tls_private_key.webssh.public_key_openssh
}

resource "null_resource" "webkey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.webssh.private_key_pem}\" > ${aws_key_pair.webssh.key_name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}
