#!/usr/bin/env bash

set -euo pipefail

QUIT_DOCKER=false
if [[ "${1:-}" == "--quit-docker" ]]; then
  QUIT_DOCKER=true
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command helm
require_command kubectl
require_command minikube

uninstall_release() {
  local release_name="$1"

  if helm status "${release_name}" -n default >/dev/null 2>&1; then
    echo "Uninstalling Helm release: ${release_name}"
    helm uninstall "${release_name}" -n default --wait --timeout 120s >/dev/null 2>&1 || true
  fi
}

echo "Performing full teardown of the PoV simulator and Grafana monitoring stack..."
echo "For a normal daily stop, prefer: ./scripts/stop-minikube.sh"

echo "Uninstalling the PoV simulator release..."
uninstall_release pov-sim

echo "Uninstalling Grafana Kubernetes monitoring..."
uninstall_release grafana-k8s-monitoring-alloy-receiver
uninstall_release grafana-k8s-monitoring-alloy-singleton
uninstall_release grafana-k8s-monitoring-alloy-metrics
uninstall_release grafana-k8s-monitoring-alloy-profiles

if helm status grafana-k8s-monitoring -n default >/dev/null 2>&1; then
  helm uninstall grafana-k8s-monitoring -n default --no-hooks --wait --timeout 120s >/dev/null 2>&1 || true
fi

echo "Cleaning up any leftover Grafana monitoring resources..."
kubectl delete job grafana-k8s-monitoring-add-finalizer -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete job grafana-k8s-monitoring-remove-alloy-and-finalizer -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete alloy --all -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete deploy grafana-k8s-monitoring-alloy-operator -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete svc grafana-k8s-monitoring-alloy-metrics grafana-k8s-monitoring-alloy-profiles grafana-k8s-monitoring-alloy-receiver grafana-k8s-monitoring-alloy-singleton -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete replicaset -l app.kubernetes.io/instance=grafana-k8s-monitoring -n default --ignore-not-found >/dev/null 2>&1 || true

echo "Stopping Minikube..."
minikube stop

if [[ "${QUIT_DOCKER}" == "true" ]]; then
  echo "Quitting Docker Desktop..."
  osascript -e 'quit app "Docker"'
else
  echo "Docker Desktop is still running."
  echo "Run this script with --quit-docker if you want it to quit Docker Desktop too."
fi

echo "Full teardown complete."
