terraform {
  backend "s3" {
    bucket         = "mysql-final-tool"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
