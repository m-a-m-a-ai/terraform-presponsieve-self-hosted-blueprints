# Restarts pods when the synced secret changes.

resource "helm_release" "reloader" {
  name             = "reloader"
  namespace        = "reloader"
  create_namespace = true
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "reloader"
  version          = "1.1.0"

  set = [
    {
      name  = "reloader.watchGlobally"
      value = "false"
    },
    {
      name  = "reloader.namespaceSelector"
      value = "kubernetes.io/metadata.name=${var.namespace}"
    },
  ]
}
