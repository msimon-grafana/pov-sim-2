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

echo "Uninstalling the PoV simulator release..."
helm uninstall pov-sim -n default >/dev/null 2>&1 || true

echo "Uninstalling Grafana Kubernetes monitoring..."
helm uninstall grafana-k8s-monitoring -n default --no-hooks >/dev/null 2>&1 || true

echo "Uninstalling any leftover Grafana Alloy sub-releases..."
helm uninstall grafana-k8s-monitoring-alloy-metrics -n default >/dev/null 2>&1 || true
helm uninstall grafana-k8s-monitoring-alloy-profiles -n default >/dev/null 2>&1 || true
helm uninstall grafana-k8s-monitoring-alloy-receiver -n default >/dev/null 2>&1 || true
helm uninstall grafana-k8s-monitoring-alloy-singleton -n default >/dev/null 2>&1 || true

echo "Cleaning up any leftover Grafana monitoring resources..."
kubectl delete job grafana-k8s-monitoring-remove-alloy-and-finalizer -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete alloy --all -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete deploy grafana-k8s-monitoring-alloy-operator -n default --ignore-not-found >/dev/null 2>&1 || true
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

echo "Shutdown complete."
