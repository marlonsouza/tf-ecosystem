terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Event Scheduler"
      CreatedAt = "2022-07-23"
      ManagedBy = "Terraform"
      Owner     = "Marlon Souza"
    }
  }
}