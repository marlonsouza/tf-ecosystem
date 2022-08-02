variable "aws_region" {
  type        = string
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to"
  default     = "dev"
}

variable "ACCOUNT_ID" {

}

variable "container_port" {}

variable "instance_type" {
  type        = string
  description = "The instance power"
}