output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "app_subnet_id" {
  value = aws_subnet.app.id
}

output "data_subnet_id" {
  value = aws_subnet.data.id
}

output "subnet_cidrs" {
  value = {
    public = aws_subnet.public.cidr_block
    app    = aws_subnet.app.cidr_block
    data   = aws_subnet.data.cidr_block
  }
}

output "nat_gateway_id" {
  value = var.enable_private_nat ? aws_nat_gateway.main[0].id : null
}
