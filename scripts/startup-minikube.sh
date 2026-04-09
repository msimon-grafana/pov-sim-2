#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

print_missing_env_help() {
  cat >&2 <<'EOF'
Missing one or more required environment variables.

Before running this script, export the required tokens in your shell:

  export GRAFANA_CLOUD_TOKEN='your-grafana-cloud-token'
  export SYNTHETIC_MONITORING_API_TOKEN='your-synthetic-monitoring-api-token'

Optional overrides:

  export OTLP_USERNAME='1537131'
  export PYROSCOPE_USERNAME='1537131'
  export PYROSCOPE_SERVER_ADDRESS='https://profiles-prod-025.grafana.net'
  export FARO_URL='https://faro-collector-prod-us-east-1.grafana.net/collect/...'
  export FARO_APP_NAME='POV-SIM'
  export FARO_APP_VERSION='1.0.0'
  export FARO_ENVIRONMENT='minikube'
  export SYNTHETIC_MONITORING_API_SERVER='synthetic-monitoring-grpc-us-east-1.grafana.net:443'
  export SYNTHETIC_MONITORING_IMAGE_REPOSITORY='grafana/synthetic-monitoring-agent'
  export SYNTHETIC_MONITORING_IMAGE_TAG='v0.55.0-browser'

Then rerun:

  ./scripts/startup-minikube.sh
EOF
}

require_envs() {
  local missing=0
  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      echo "Missing required environment variable: $name" >&2
      missing=1
    fi
  done

  if [[ "${missing}" -eq 1 ]]; then
    echo >&2
    print_missing_env_help
    exit 1
  fi
}

require_command docker
require_command minikube
require_command kubectl
require_command helm

require_envs GRAFANA_CLOUD_TOKEN SYNTHETIC_MONITORING_API_TOKEN

OTLP_USERNAME="${OTLP_USERNAME:-1537131}"
PYROSCOPE_USERNAME="${PYROSCOPE_USERNAME:-1537131}"
PYROSCOPE_SERVER_ADDRESS="${PYROSCOPE_SERVER_ADDRESS:-https://profiles-prod-025.grafana.net}"
FARO_URL="${FARO_URL:-https://faro-collector-prod-us-east-1.grafana.net/collect/3648756f5ae493ee16070dceb1856a44}"
FARO_APP_NAME="${FARO_APP_NAME:-POV-SIM}"
FARO_APP_VERSION="${FARO_APP_VERSION:-1.0.0}"
FARO_ENVIRONMENT="${FARO_ENVIRONMENT:-minikube}"
SYNTHETIC_MONITORING_API_SERVER="${SYNTHETIC_MONITORING_API_SERVER:-synthetic-monitoring-grpc-us-east-1.grafana.net:443}"
SYNTHETIC_MONITORING_IMAGE_REPOSITORY="${SYNTHETIC_MONITORING_IMAGE_REPOSITORY:-grafana/synthetic-monitoring-agent}"
SYNTHETIC_MONITORING_IMAGE_TAG="${SYNTHETIC_MONITORING_IMAGE_TAG:-v0.55.0-browser}"

cd "${REPO_ROOT}"

echo "Checking Docker availability..."
docker info >/dev/null

echo "Starting Minikube if needed..."
if ! minikube status >/dev/null 2>&1; then
  minikube start
else
  minikube start
fi

eval "$(minikube docker-env)"

echo "Building application images into the Minikube Docker daemon..."
docker build -t airlines:latest ./airlines
docker build -t flights:latest ./flights
docker build -t react-app:latest ./frontend

echo "Installing Grafana Helm repo..."
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

echo "Installing Grafana Kubernetes monitoring..."
helm upgrade --install grafana-k8s-monitoring grafana/k8s-monitoring \
  --namespace default \
  --create-namespace \
  --values - <<EOF
cluster:
  name: POV-SIM

destinations:
  gc-otlp-endpoint:
    type: otlp
    url: https://otlp-gateway-prod-us-east-1.grafana.net/otlp
    protocol: http
    auth:
      type: basic
      username: "${OTLP_USERNAME}"
      password: "${GRAFANA_CLOUD_TOKEN}"
    metrics:
      enabled: true
    logs:
      enabled: true
    traces:
      enabled: true

  grafana-cloud-profiles:
    type: pyroscope
    url: ${PYROSCOPE_SERVER_ADDRESS}:443
    auth:
      type: basic
      username: "${PYROSCOPE_USERNAME}"
      password: "${GRAFANA_CLOUD_TOKEN}"

telemetryServices:
  kube-state-metrics:
    deploy: true

applicationObservability:
  enabled: true
  collector: alloy-receiver
  receivers:
    otlp:
      grpc:
        enabled: true
        port: 4317
      http:
        enabled: true
        port: 4318
  destinations:
    - gc-otlp-endpoint

profiling:
  enabled: true
  collector: alloy-profiles
  destinations:
    - grafana-cloud-profiles

podLogs:
  enabled: true
  collector: alloy-singleton
  destinations:
    - gc-otlp-endpoint

clusterEvents:
  enabled: true
  collector: alloy-singleton
  destinations:
    - gc-otlp-endpoint

clusterMetrics:
  enabled: true
  collector: alloy-metrics
  destinations:
    - gc-otlp-endpoint
  opencost:
    enabled: false
  kepler:
    enabled: false

collectors:
  alloy-receiver:
    enabled: true
  alloy-singleton:
    enabled: true
  alloy-metrics:
    enabled: true
  alloy-profiles:
    enabled: true

autoInstrumentation:
  enabled: false
EOF

echo "Installing the PoV simulator chart..."
helm upgrade --install pov-sim ./helm-charts/pov-sim \
  --namespace default \
  --set alloy.enabled=false \
  --set observability.otlp.endpoint=http://grafana-k8s-monitoring-alloy-receiver.default.svc.cluster.local:4317 \
  --set observability.otlp.protocol=grpc \
  --set secrets.pyroscopeServerAddress="${PYROSCOPE_SERVER_ADDRESS}" \
  --set secrets.pyroscopeBasicAuthUser="${PYROSCOPE_USERNAME}" \
  --set secrets.pyroscopeBasicAuthPassword="${GRAFANA_CLOUD_TOKEN}" \
  --set airlines.pyroscopeApplicationName=airlines-direct-to-cloud \
  --set flights.pyroscopeApplicationName=flights-direct-to-cloud \
  --set frontend.env.faroUrl="${FARO_URL}" \
  --set frontend.env.faroAppName="${FARO_APP_NAME}" \
  --set frontend.env.faroAppVersion="${FARO_APP_VERSION}" \
  --set frontend.env.faroEnvironment="${FARO_ENVIRONMENT}" \
  --set syntheticMonitoring.enabled=true \
  --set syntheticMonitoring.apiServerAddress="${SYNTHETIC_MONITORING_API_SERVER}" \
  --set syntheticMonitoring.image.repository="${SYNTHETIC_MONITORING_IMAGE_REPOSITORY}" \
  --set syntheticMonitoring.image.tag="${SYNTHETIC_MONITORING_IMAGE_TAG}" \
  --set secrets.syntheticMonitoringApiToken="${SYNTHETIC_MONITORING_API_TOKEN}"

echo
echo "Startup complete."
echo "Next:"
echo "  kubectl get pods -n default"
echo "  kubectl port-forward svc/pov-sim-frontend 3000:3000 -n default"
