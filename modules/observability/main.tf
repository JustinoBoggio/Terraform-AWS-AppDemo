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
  create_namespace = false

  values = [ yamlencode({
    args = [
      "--kubelet-insecure-tls",
      "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP"
    ]
  }) ]
}


# ---- kube-prometheus-stack (Prom + Grafana + Alertmanager) ----
resource "helm_release" "kps" {
  count            = var.enable_kube_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  namespace        = var.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  create_namespace = false
  depends_on       = [kubernetes_namespace.this]

  # Para evitar estados “failed” colgados y esperas cortas
  atomic          = true           # si falla, desinstala
  cleanup_on_fail = true
  timeout         = 1200           # 20 min para CRDs y operator
  wait            = true
  dependency_update = true

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
          storage   = null
          resources = {
            requests = { cpu = "20m", memory = "64Mi" }
            limits   = { cpu = "100m", memory = "128Mi" }
          }
        }
      }

      prometheus = {
        service = { type = "ClusterIP" }
        prometheusSpec = {
          retention     = var.prometheus_retention
          storageSpec   = null
          scrapeInterval = "30s"
          resources = {
            requests = { cpu = "150m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }

        # ServiceMonitor para tu API (solo si lo habilitaste por var)
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
                port     = var.app_api_metrics_port
                path     = var.app_api_metrics_path
                interval = var.app_api_scrape_interval
              }
            ]
          }
        ] : []
      }

      # En EKS los componentes de control-plane NO están como pods accesibles
      kubeControllerManager = { enabled = false }
      kubeScheduler         = { enabled = false }
      kubeProxy             = { enabled = false }
      kubeEtcd              = { enabled = false }

      # Reglas por defecto OK; si deshabilitás etcd arriba, podés evitar sus rules
      defaultRules = {
        rules = {
          etcd = false
        }
      }
    })
  ]
}
