##################################################
# AWS
##################################################

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

##################################################
# Helm Release Variables - Enable SSL
# corresponds to input to resource "helm_release"
##################################################

variable "letsencrypt_email" {
  type        = string
  description = "Email to use for https setup. Not needed unless enable_ssl"
}

variable "aws_route53_zone_name" {
  type        = string
  description = "Name of the zone to add records. Do not forget the trailing '.' - 'test.com.'"
}
