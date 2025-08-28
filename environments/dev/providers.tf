provider "aws" {
  region  = "us-east-1"
  profile = "tf-admin"
  default_tags {
    tags = {
      Project = "justino-devops-lab"
      Env     = "dev"
      Owner   = "justino"
    }
  }
}