provider "null" {}

resource "null_resource" "wsl_kubernetes" {
  triggers = {
    kubernetes_version = var.kubernetes_version
  }

  provisioner "local-exec" {
    command = "${path.module}/../scripts/install-wsl-kubernetes.sh ${var.kubernetes_version}"
  }
}

resource "null_resource" "network_instructions" {
  depends_on = [null_resource.wsl_kubernetes]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/configure-wsl-network.sh ${var.node_port}"
  }
}