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

require_command minikube

echo "Stopping Minikube..."
minikube stop

if [[ "${QUIT_DOCKER}" == "true" ]]; then
  if command -v osascript >/dev/null 2>&1; then
    echo "Quitting Docker Desktop..."
    osascript -e 'quit app "Docker"'
  else
    echo "osascript is not available, so Docker Desktop was not quit automatically." >&2
  fi
else
  echo "Docker Desktop is still running."
  echo "Run this script with --quit-docker if you want it to quit Docker Desktop too."
fi

echo "Minikube stop complete."
