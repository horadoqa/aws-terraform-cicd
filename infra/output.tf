output "instance_public_ip" {
  description = "O IP público da instância EC2"
  value       = aws_instance.k6[*].public_ip
}