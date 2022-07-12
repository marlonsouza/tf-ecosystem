terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "TF Ecosystem"
      CreatedAt = "2022-07-11"
      ManagedBy = "Terraform"
      Owner     = "Marlon Souza"
    }
  }
}
