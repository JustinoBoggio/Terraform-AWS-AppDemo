plugin "aws" {
  enabled = true
  # Dejá que baje la última release estable (evita 404 por tags viejas).
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  # Reemplaza el viejo "module = true"
  call_module_type = "all"
}