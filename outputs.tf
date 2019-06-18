# ELB dns name
output "elb_dns_name" {
    description = "DNS Name of the ELB"
    value = "${aws_elb.Zane-elb.dns_name}"
}