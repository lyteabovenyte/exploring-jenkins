output "bastion_public_ip" {
    value = "${aws_instance.bastion.public_ip}"
}

output "jenkins-master-elb" {
    description = "load balancer DNS URL"
    value = aws_elb.jenkins_elb.dns_name
}