output "repositories" {
  value = {
    for k, v in aws_ecr_repository.this :
    k => {
      arn = v.arn
      url = v.repository_url
    }
  }
}
