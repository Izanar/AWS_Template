output "public_ip" {
  value = module.ec2_webserver.public_ip
}

output "instance_id" {
  value = module.ec2_webserver.instance_id
}