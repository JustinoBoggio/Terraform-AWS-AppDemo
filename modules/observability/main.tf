# Namespace para observabilidad
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# ---- metrics-server (barato, necesario para HPA/kubectl top) ----
resource "helm_release" "metrics_server" {
  count            = var.enable_metrics_server ? 1 : 0
  name             = "metrics-server"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  # version        = "3.12.1" # opcional, podés fijarla; si te falla, comentala
  create_namespace = false

  # flags útiles en EKS
  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP"
  }
  set {
    name  = "args[1]"
    value = "--kubelet-insecure-tls"
  }
}

# ---- kube-prometheus-stack (Prom + Grafana + Alertmanager) ----
resource "helm_release" "kps" {
  count            = var.enable_kube_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  namespace        = var.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  # version        = "58.3.0" # opcional: fijá versión; si no existe, quita esta línea
  create_namespace = false
  depends_on       = [kubernetes_namespace.this]

  # Valores mínimos para costo bajo (sin PVCs, ClusterIP, retention corta)
  values = [
    yamlencode({
      grafana = {
        enabled = var.grafana_enabled
        service = { type = "ClusterIP" }
        adminPassword = var.grafana_admin_password
        resources = {
          requests = { cpu = "50m",  memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      alertmanager = {
        enabled = true
        service = { type = "ClusterIP" }
        alertmanagerSpec = {
          retention = "120h"
          storage   = null # sin PVC (emptyDir)
          resources = {
            requests = { cpu = "20m", memory = "64Mi" }
            limits   = { cpu = "100m", memory = "128Mi" }
          }
        }
      }

      prometheus = {
        service = { type = "ClusterIP" }
        prometheusSpec = {
          retention   = var.prometheus_retention
          storageSpec = null # sin PVC (emptyDir)
          resources = {
            requests = { cpu = "150m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
          scrapeInterval = "30s"
        }

        # 👉 ServiceMonitor para tu app-api (renderizado por el chart)
        additionalServiceMonitors = var.app_api_service_monitor_enabled ? [
          {
            name = "app-api"
            namespaceSelector = {
              matchNames = [var.app_api_namespace]
            }
            selector = {
              matchLabels = {
                "app.kubernetes.io/instance" = var.app_api_label_instance
                "app.kubernetes.io/name"     = var.app_api_label_name
              }
            }
            endpoints = [
              {
                port     = var.app_api_metrics_port   # debe existir en el Service (name: http)
                path     = var.app_api_metrics_path
                interval = var.app_api_scrape_interval
              }
            ]
          }
        ] : []
      }

      kubeControllerManager = { enabled = true }
      kubeScheduler         = { enabled = true }
      kubeProxy             = { enabled = true }
      kubeEtcd              = { enabled = true }
      nodeExporter          = { enabled = true }
      kubeStateMetrics      = { enabled = true }
    })
  ]
}