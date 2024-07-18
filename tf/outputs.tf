output "bastion_public_ip" {
    value = "${aws_instance.bastion.public_ip}"
    description = "bastion host public ip, used to ssh into the private master jenkins subnet."
}

output "jenkins-master-elb" {
    description = "load balancer DNS URL"
    value = aws_elb.jenkins_elb.dns_name
}

output "jenkins-dns" {
    value = "https://${aws_route53_record.jenkins_master.name}"
    description = "jenkin's public DNS URL by referencing the Route53 A record."
}