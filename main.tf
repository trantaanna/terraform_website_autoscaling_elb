
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

#resource "aws_instance" "example" {
#  ami           = "ami-2757f631"
#  instance_type = "t2.micro"
#}

# Get availability zones for the region specified in var.region
data "aws_availability_zones" "all" {}


###############################################################
# Launch configuration to deploy two AWS webservers
###############################################################

# Create launch configuration
resource "aws_launch_configuration" "Zane-lc" {
  name = "Zane-lc"
  image_id = "ami-a0cfeed8"
  instance_type = "t2.nano"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.Zane-lc-sg.id}"]

  iam_instance_profile = "${var.iam_instance_profile}"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo service httpd start
              sudo chkconfig httpd on
              aws s3 cp "${var.s3_bucket}" /var/www/html/ --recursive
              hostname -f >> /var/www/html/index.html
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################
# Autoscaling
###############################################################

# Create autoscaling policy -> target at a 65% average CPU load
resource "aws_autoscaling_policy" "Zane-asg-policy-1" {
  name                   = "Zane-asg-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.Zane-asg.name}"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 65.0
  }
}

# Create an autoscaling group
resource "aws_autoscaling_group" "Zane-asg" {
  name = "Zane-asg"
  launch_configuration = "${aws_launch_configuration.Zane-lc.id}"
  availability_zones = "${data.aws_availability_zones.all.names}"
  

  min_size = 2
  max_size = 5

  load_balancers = ["${aws_elb.Zane-elb.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "Zane-ASG"
    propagate_at_launch = true
  }
}

###############################################################
# ELB
###############################################################
# Create the ELB
resource "aws_elb" "Zane-elb" {
  name = "Zane-elb"
  security_groups = ["${aws_security_group.Zane-elb-sg.id}"]
  availability_zones = "${data.aws_availability_zones.all.names}"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    #target = "TCP:${var.server_port}"
    target = "HTTP:${var.server_port}/index.html"
  }

  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}

###############################################################
# Security group
###############################################################
# Create security group that's applied the launch configuration
resource "aws_security_group" "Zane-lc-sg" {
  name = "Zane-lc-sg"

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.ssh_port}"
    to_port = "${var.ssh_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound internet access
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create security group that's applied to the ELB
resource "aws_security_group" "Zane-elb-sg" {
  name = "Zane-elb-sg"

  # Allow all outbound
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

