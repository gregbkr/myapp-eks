provider "aws" {
  version = "~> 2.61" 
  region     = "eu-west-1"
}



# Will we store our state in S3, and lock with dynamodb
# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket         = "terraform-up-and-running-state-gg"
#     key            = "covid/prod/terraform.tfstate"
#     region         = "eu-west-3"
#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "terraform-up-and-running-locks"
#     encrypt        = true
#   }
# }

# VARIABLE

variable "tag" {
  default = "hello-terra-bkr"
}
variable "owner" {
  default = "gregbkr"
} 
variable "repo" {
  default = "eks-terraform-codepipeline"
}
variable "gitHubToken" {
  default = "to-set-via-env-variable"
}


# Fist get the default VPC and subnet IDs
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

output "iam_build_role_arn" {
  value = aws_iam_role.build_role.arn
}

output "subnets" {
  value = data.aws_subnet_ids.default
}