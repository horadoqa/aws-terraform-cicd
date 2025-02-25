resource "aws_instance" "k6" {
  count         = var.number_instances
  ami           = var.aws_ami
  instance_type = var.instance_type
  user_data = file("user-data.sh")

  security_groups = [aws_security_group.allow_ssh_http.name]

  tags = {
    Name = "k6-${count.index}"
  }
}
