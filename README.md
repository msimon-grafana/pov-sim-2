# 🚀 PoV Flight Simulator 🚀

Welcome to the PoV Flight Simulator

- [About](#about)
- [Getting Up and Running](#getting-up-and-running)
  - [Prerequisites](#prerequisites)
  - [Spin up all services](#spin-up-all-services)
  - [Spin up the `airlines` service](#spin-up-the-airlines-service)
  - [Spin up the `flights` service](#spin-up-the-flights-service)
  - [Spin up the `frontend` service](#spin-up-the-frontend-service)
- [Simulate traffic to the services](#simulate-traffic-to-the-services)
  - [airlines-loadgen](#running-airlines-loadgen)
  - [flights-loadgen](#running-flights-loadgen)

# About

This application comprises the following services:

| Name | Description | Tech | Quick Link |
| :---: | :---: | :---: | :---: |
| `airlines` | Backend service | Java Spring Boot app | http://localhost:8080/swagger-ui/index.html#/ |
| `flights` | Backend service | Python Flask app | http://localhost:5001/apidocs/ |
| `frontend` | Frontend service | React app | http://localhost:3000/ |
|||

The `frontend` service is a simple React app that make API requests to both the `airlines` and `flights` services.
![alt text](resources/povsim.png)

# Getting Up and Running

## Prerequisites

- Install [Docker](https://docs.docker.com/engine/install/) on your local machine
- Clone this repo to your local machine
```
git clone https://github.com/aninamu/pov-sim.git
```

## Spin up all services

From the project root, run all the services with the following command:
```
make up
```

- *The `airlines` service will run on http://localhost:8080/ with Swagger doc UI at http://localhost:8080/swagger-ui/index.html#/*
- *The `flights` service will run on http://localhost:5001/ with Swagger doc UI at http://localhost:5001/apidocs/*
- *The `frontend` service will run on http://localhost:3000/*

Stop the services with the following command:
```
make down
```

Continue reading to see how to spin up an individual service as opposed to running all services at once.

## Spin up the `airlines` service   

From the `airlines` directory:

Build the app
```
make build
```

Run the app
```
make run
```
*The `airlines` service will run on http://localhost:8080/ with Swagger doc UI at http://localhost:8080/swagger-ui/index.html#/*

Alternatively, use a single command to both build and run the app
```
make start
```

Gracefully stop the app
```
make stop
```

Clean up the container(s)
```
make clean
```

## Spin up the `flights` service

From the `flights` directory:

Build the app
```
make build
```

Run the app
```
make run
```
*The `flights` service will run on http://localhost:5001/ with Swagger doc UI at http://localhost:5001/apidocs/*

Alternatively, use a single command to both build and run the app
```
make start
```

Gracefully stop the app
```
make stop
```

Clean up the container(s)
```
make clean
```

## Spin up the `frontend` service

From the `frontend` directory:

Build the app
```
make build
```

Run the app
```
make run
```
*The `frontend` service will run on http://localhost:3000/*

Gracefully stop the app
```
make stop
```

# Simulate traffic to the services

The `scripts/` directory includes load generator scripts you can use to make batch sets of requests to your running services.

- The `airlines-loadgen.sh` script generates load to the `airlines` service
- The `flights-loadgen.sh` script generates load to the `flights` service

## Running airlines-loadgen

*Note: You may need to run the following command to add the proper permissions to execute the script*
```
chmod +x airlines-loadgen.sh
```

The `airlines-loadgen` script makes API requests to the `airlines` service. You can optionally specify the following parameters to the script:
- An error rate `-e` to force the requests to the service to error out at that rate
- A duration `-d` to specify the number of seconds the script should run
- A base URL `-b` if you are running the service on a port other than the default

From the `scripts/` directory:

- Run the script with default params
  ```
  ./airlines-loadgen.sh
  ```

- View usage
  ```
  ./airlines-loadgen.sh -h
  ```

- Example: Run the script for 120 seconds generating a 25% error rate within the `airlines` service
  ```
  ./airlines-loadgen.sh -e 0.25 -d 120
  ```

## Running flights-loadgen

*Note: You may need to run the following command to add the proper permissions to execute the script*
```
chmod +x flights-loadgen.sh
```

The `flights-loadgen` script makes API requests to the `flights` service. You can optionally specify the following parameters to the script:
- An error rate `-e` to force the requests to the service to error out at that rate
- A duration `-d` to specify the number of seconds the script should run
- A base URL `-b` if you are running the service on a port other than the default

From the `scripts/` directory:

- Run the script with default params
  ```
  ./flights-loadgen.sh
  ```

- View usage
  ```
  ./flights-loadgen.sh -h
  ```

- Example: Run the script for 120 seconds generating a 25% error rate within the `flights` service
  ```
  ./flights-loadgen.sh -e 0.25 -d 120
  ```

# Deploying a Helm chart

You may wish to deploy a Helm chart to complete one of the tasks. This repo contains an example Helm chart that can be used for a sample Kubernetes deployment.

Included is a recommended approach for using [Minikube](https://minikube.sigs.k8s.io/docs/) to deploy a local Kubernetes cluster.

## Prerequisites

- Install minikube https://minikube.sigs.k8s.io/docs/start/
- Install helm https://helm.sh/docs/intro/install/

## Getting up and running

Start your cluster
```
minikube start
```

Option to view the local Kubernetes dashboard
```
minikube dashboard
```

Install the sample Helm chart
```
helm install sample-chart helm-charts/sample-chart
```

Confirm the pod is up and running
```
kubectl get pods
```

## Deploying the full PoV simulator with Helm

The sample chart above is only a starter. For the full stack in this repo, use the chart in [`helm-charts/pov-sim`](/Users/msimon/Documents/Playground/pov-sim-2/helm-charts/pov-sim).

Build the application images into your local cluster runtime first. For Minikube, one option is:
```
eval $(minikube docker-env)
docker build -t airlines:latest ./airlines
docker build -t flights:latest ./flights
docker build -t react-app:latest ./frontend
```

Install the chart:
```
helm upgrade --install pov-sim ./helm-charts/pov-sim \
  --set secrets.cloudOtlpEndpoint="https://YOUR_OTLP_ENDPOINT.grafana.net/otlp" \
  --set secrets.cloudOtlpUsername="YOUR_OTLP_USERNAME" \
  --set secrets.cloudOtlpPassword="YOUR_OTLP_TOKEN"
```

If you also want Pyroscope credentials configured, add:
```
  --set secrets.pyroscopeServerAddress="https://YOUR-PYROSCOPE-ENDPOINT.grafana.net" \
  --set secrets.pyroscopeBasicAuthUser="YOUR_PYROSCOPE_USER" \
  --set secrets.pyroscopeBasicAuthPassword="YOUR_PYROSCOPE_PASSWORD"
```

Access the app locally:
```
kubectl port-forward svc/pov-sim-frontend 3000:3000
```

Then open:
```
http://127.0.0.1:3000
```

The frontend defaults to `/airlines` and `/flights` and proxies those requests to the in-cluster backend services, so you do not need separate port-forwards for the APIs.

### Java profiling in Kubernetes

The `airlines` image now downloads a pinned Pyroscope Java agent during image build and starts the JVM with both the OpenTelemetry Java agent and the Pyroscope Java agent. The image also includes the recommended JVM flags for async-profiler stack accuracy.

As of April 7, 2026, Grafana's Java profiling docs still show `io.pyroscope:agent:2.1.2`, while Maven Central lists newer releases. This repo pins `2.5.1` from Maven Central in [`airlines/Dockerfile`](/Users/msimon/Documents/Playground/pov-sim-2/airlines/Dockerfile) to keep builds reproducible instead of relying on a moving `latest` URL. Sources: [Grafana Java profiling docs](https://grafana.com/docs/pyroscope/latest/configure-client/language-sdks/java/), [Maven Central](https://central.sonatype.com/artifact/io.pyroscope/agent).

### Using Grafana k8s-monitoring instead of the bundled Alloy receiver

If you install Grafana's `k8s-monitoring` Helm chart from the Cloud UI, you can point the app pods at that receiver and disable the bundled `alloy` in this chart.

The chart now supports an OTLP endpoint override:
```
helm upgrade --install pov-sim ./helm-charts/pov-sim \
  --set alloy.enabled=false \
  --set observability.otlp.endpoint="http://YOUR-OTLP-RECEIVER-SERVICE:4317" \
  --set observability.otlp.protocol=grpc \
  --set secrets.pyroscopeServerAddress="https://YOUR-PYROSCOPE-ENDPOINT.grafana.net" \
  --set secrets.pyroscopeBasicAuthUser="YOUR_PYROSCOPE_USER" \
  --set secrets.pyroscopeBasicAuthPassword="YOUR_PYROSCOPE_PASSWORD"
```

That maps well to the Grafana Cloud `k8s-monitoring` install command you shared, especially these features:
- `applicationObservability.receivers.otlp` gives you an in-cluster OTLP receiver for app telemetry.
- `profiling.enabled` and `alloy-profiles.enabled` align with sending profiles into Grafana Cloud Profiles.
- `podLogs.enabled`, `clusterMetrics.enabled`, and `clusterEvents.enabled` cover Kubernetes-level telemetry that this app chart does not try to manage.

The exact receiver service name can vary by release, so after installing `grafana/k8s-monitoring`, check it with:
```
kubectl get svc
```
