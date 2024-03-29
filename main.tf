provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}

terraform {
  required_version = ">=1.4.5"
  backend "s3" {
    bucket = "philo-web-terraform-state"
    key    = "philomusica.tfstate"
    region = "eu-west-1"
  }
}

