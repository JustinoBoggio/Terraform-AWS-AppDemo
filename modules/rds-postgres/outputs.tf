output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "security_group_id" {
  value = aws_security_group.db.id
}

output "username" {
  value = aws_db_instance.this.username
}

output "password" {
  value = random_password.db.result
}
