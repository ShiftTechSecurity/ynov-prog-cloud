output "web_security_group_id" {
  value = aws_security_group.web.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "security_group_names" {
  value = {
    web = aws_security_group.web.name
    app = aws_security_group.app.name
    db  = aws_security_group.db.name
  }
}
