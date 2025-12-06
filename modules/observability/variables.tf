variable "enable_metrics_server" {
  type    = bool
  default = true
}

variable "enable_kube_prometheus_stack" {
  type    = bool
  default = true
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "grafana_enabled" {
  type    = bool
  default = true
}

variable "grafana_admin_password" {
  type    = string
  default = null
}

variable "prometheus_retention" {
  type    = string
  default = "3d"
}

variable "app_api_service_monitor_enabled" {
  type    = bool
  default = true
}

variable "app_api_namespace" {
  type    = string
  default = "app"
}

variable "app_api_label_instance" {
  type    = string
  default = "app-api"
}

variable "app_api_label_name" {
  type    = string
  default = "app"
}

variable "app_api_metrics_port" {
  type    = string
  default = "http"
}

variable "app_api_metrics_path" {
  type    = string
  default = "/metrics"
}

variable "app_api_scrape_interval" {
  type    = string
  default = "30s"
}
