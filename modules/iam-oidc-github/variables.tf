variable "create_provider" {
  description = "Whether to create the GitHub OIDC provider in this account (set to false if already exists)"
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "GitHub Organization or Username"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository name"
  type        = string
}

variable "allowed_refs" {
  description = "List of allowed GitHub references (branches, tags, PRs) that can assume the role"
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "role_name" {
  description = "Name of the IAM role to be created for GitHub Actions"
  type        = string
  default     = "gha-terraform-dev"
}

variable "policy_arns" {
  description = "List of IAM Managed Policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}