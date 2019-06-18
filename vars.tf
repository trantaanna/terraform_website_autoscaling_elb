#required for AWS
variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "us-west-2"
}
variable key_name {}    #AWS SSH keyname
variable iam_instance_profile {}    #AWS IAM profile for access to S3

# specific to the site
variable "site_domain" {    
    default = "onezaneprop.com"
    description = "The domain name of the site we are creating"
}

variable "s3_bucket" {
    default = "filestorage-zane"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

variable "ssh_port" {
  default = 22
}

