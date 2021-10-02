output "prod_elb_url" {
  value = aws_elb.prod.dns_name
}
