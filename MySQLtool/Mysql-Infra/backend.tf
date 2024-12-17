terraform {
  backend "s3" {
    bucket         = "ninja-tool"
    key            = "east.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "abc-tool"
    encrypt        = true
  }
}
