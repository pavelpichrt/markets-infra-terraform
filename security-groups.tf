resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "vpc_and_home" {
  name        = "vpc_and_home"
  description = "Connections from VPC and home IPs"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description     = "All Traffic"
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = [var.ip_home]
    security_groups = [aws_default_security_group.default.id]
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc_and_home"
  }
}
