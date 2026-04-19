terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

locals {
  base_tags = {
    owner = "platform"
  }
}

variable "cidr" {
  type      = string
  sensitive = false
  validation {
    condition     = length(var.cidr) > 0
    error_message = "cidr must not be empty"
  }
}

variable "subnets" {
  type = map(string)
}

variable "settings" {
  type = object({ env = string, retries = number })
}

variable "env" {
  type    = string
  default = "dev"
}

variable "secret_key" {
  type      = string
  sensitive = true
}

module "network_labels" {
  source     = "./modules/labels"
  depends_on = [data.aws_caller_identity.current]
  providers  = { aws = aws.east }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "main" {
  provider   = aws.east
  cidr_block = var.cidr
  count      = 1
  depends_on = [module.network_labels]

  lifecycle {
    prevent_destroy       = true
    create_before_destroy = true
    ignore_changes        = [tags]
    precondition {
      condition     = var.cidr != ""
      error_message = "cidr cannot be blank"
    }
    postcondition {
      condition     = self.id != ""
      error_message = "id should be assigned"
    }
  }

}

resource "aws_subnet" "this" {
  depends_on = [data.aws_caller_identity.current]
  for_each   = var.subnets
  vpc_id     = aws_vpc.main[0].id
  cidr_block = each.value
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main[0].id

  dynamic "ingress" {
    for_each = local.base_tags
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.cidr]
    }
  }
}

check "subnet_count" {
  assert {
    condition     = length(var.subnets) > 0
    error_message = "subnets required"
  }
}

output "vpc_id" {
  value = aws_vpc.main[0].id
}

output "vpc_id_sensitive" {
  value      = aws_vpc.main[0].id
  sensitive  = true
  depends_on = [aws_vpc.main]
}
