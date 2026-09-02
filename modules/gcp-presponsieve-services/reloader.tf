# Restarts pods when the synced secret changes, so a renewed license or a
# rotated pepper does not need a manual rollout.

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
