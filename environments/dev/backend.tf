terraform {
  backend "s3" {
    bucket         = "tf-justino-tfstate-215873709989-us-east-1"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-justino-tf-lock"
    encrypt        = true
  }
}