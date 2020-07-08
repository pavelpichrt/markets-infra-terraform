resource "aws_instance" "postgres" {
  key_name               = aws_key_pair.terraform_key.key_name
  ami                    = var.amis_debian_stretch
  instance_type          = "t3a.medium"
  vpc_security_group_ids = [aws_security_group.vpc_and_home.id]
  availability_zone      = data.aws_availability_zones.available.names[0]
  ebs_optimized          = true

  root_block_device {
    volume_size = 30
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file(var.priv_key_file)
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./scripts/setup-postgres.sh"
    destination = "/tmp/setup-postgres.sh"
  }

  provisioner "file" {
    source      = "./scripts/ddl.sql"
    destination = "~/ddl.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-postgres.sh",
      "sudo bash /tmp/setup-postgres.sh ${var.PG_PWD}",
    ]
  }
}

resource "aws_eip" "pg_instance" {
  instance = aws_instance.postgres.id
  vpc      = true
}
