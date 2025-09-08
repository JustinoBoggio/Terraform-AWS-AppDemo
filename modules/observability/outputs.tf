output "grafana_port_forward" {
  value = var.enable_kube_prometheus_stack && var.grafana_enabled ? "kubectl -n ${var.namespace} port-forward svc/kube-prometheus-stack-grafana 3001:80": null
}

output "prometheus_url_hint" {
  value = var.enable_kube_prometheus_stack ? "After port-forward to Grafana, datasource 'Prometheus' is pre-wired. Explore -> Metrics -> up{}": null
}