resource "aws_instance" "website" {
  count         = var.number_instances
  ami           = var.aws_ami
  instance_type = var.instance_type

  security_groups = [aws_security_group.allow_ssh_http.name]
  key_name        = aws_key_pair.horadoqa.key_name

  tags = {
    Name = "Website"
  }
}

resource "aws_key_pair" "horadoqa" {
  key_name   = "aws-instance-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

