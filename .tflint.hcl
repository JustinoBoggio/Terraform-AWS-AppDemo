plugin "aws" {
  enabled = true
  version = "0.40.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  # reemplaza el viejo "module = true"
  call_module_type = "all"
}