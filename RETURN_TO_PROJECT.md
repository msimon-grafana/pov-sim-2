# Return To Project

## Start Up

1. Open Docker Desktop and wait for it to finish booting.
2. Open a terminal and go to the repo:
   ```bash
   cd /Users/msimon/Documents/Playground/pov-sim-2
   git checkout k8s-minikube-setup
   git pull --ff-only
   ```
3. Export the required tokens:
   ```bash
   export GRAFANA_CLOUD_TOKEN='your-grafana-cloud-token'
   export SYNTHETIC_MONITORING_API_TOKEN='your-synthetic-monitoring-token'
   ```
4. Start the stack:
   ```bash
   ./scripts/startup-minikube.sh
   ```
5. Open the frontend:
   ```bash
   kubectl port-forward svc/pov-sim-frontend 3000:3000 -n default
   ```
6. Browse to:
   ```text
   http://127.0.0.1:3000
   ```

## Quick Checks

Check Minikube:

```bash
minikube status
```

Check pods:

```bash
kubectl get pods -n default
```

Check services:

```bash
kubectl get svc -n default
```

## Shut Down

1. Stop the port-forward with `Ctrl+C`.
2. Shut down the cluster:
   ```bash
   ./scripts/shutdown-minikube.sh
   ```
3. If you want a full stop, quit Docker Desktop too.

## Notes

- The startup script will tell you if required tokens are missing.
- Synthetic browser checks inside the cluster should use:
  - `http://pov-sim-frontend:3000`
  - not `http://127.0.0.1:3000`
- The working branch is:
  - `k8s-minikube-setup`
