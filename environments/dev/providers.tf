provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
  default_tags {
    tags = {
      Project = "justino-devops-lab"
      Env     = "dev"
      Owner   = "justino"
    }
  }
}