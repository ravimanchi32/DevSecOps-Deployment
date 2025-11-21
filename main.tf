terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./eks/vpc.tf"
}

module "eks" {
  source               = "./eks"
  cluster_name         = var.cluster_name
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  public_subnets       = module.vpc.public_subnets
  node_group_instance  = var.node_group_instance
  desired_size         = var.desired_size
  min_size             = var.min_size
  max_size             = var.max_size
}
