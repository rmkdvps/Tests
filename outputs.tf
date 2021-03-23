
output "vm1_instance_id" {
  value = aws_instance.vm1.id
}

output "vm2_instance_id" {
  value = aws_instance.vm2.id
}

output "vm1_public_dns" {
  value = aws_instance.vm1.public_dns
}

output "vm2_public_dns" {
  value = aws_instance.vm2.public_dns
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "gateway_id" {
  value = aws_internet_gateway.igw.id
}
