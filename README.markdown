

## Overview
This project deploys a Java Spring Boot API on Google Kubernetes Engine (GKE) with an NGINX Ingress for external access and TLS encryption. The API provides two endpoints:
- `/health`: Returns the application's health status.
- `/api/users`: Returns a list of sample user data.

The application is containerized using Docker, stored in Google Artifact Registry, and deployed to a GKE cluster in the `java-api-ns-nadun` namespace. It uses a Horizontal Pod Autoscaler (HPA) for scaling, cert-manager for TLS certificates, and monitoring capabilities via Spring Boot Actuator.

- **Project ID**: `betbazar-ops`
- **Region**: `us-central1`
- **Artifact Registry Repository**: `java-api-repo-nadun`
- **GKE Cluster**: `java-api-cluster-nadun` (zone: `us-central1-a`)
- **Namespace**: `java-api-ns-nadun`
- **Domain**: `api.nadunwansooriya.online`

## Prerequisites
- **Google Cloud Platform (GCP)**: Account with a project (`betbazar-ops`) and billing enabled.
- **gcloud CLI**: Installed and authenticated (`gcloud auth login`).
- **kubectl**: Installed and configured to access the GKE cluster.
- **Docker**: Installed for building and pushing the container image.
- **Maven**: Installed for building the Java application.
- **DNS**: Control over the domain `api.nadunwansooriya.online` for DNS configuration.

## Project Structure
```
java-api/
├── src/
│   └── main/java/com/example/api/
│       └── ApiApplication.java
├── k8s/
│   ├── 01-namespace.yaml
│   ├── 02-configmap.yaml
│   ├── 03-secret.yaml
│   ├── 04-deployment.yaml
│   ├── 05-service.yaml
│   ├── 06-hpa.yaml
│   ├── 07-certificate.yaml
│   ├── 08-ingress.yaml
│   └── letsencrypt-prod.yaml
├── scripts/
│   ├── monitor.sh
│   └── cleanup.sh
├── Dockerfile
├── pom.xml
└── .dockerignore
```

## Setup Instructions

### 1. Build the Java Application
1. Navigate to the project directory:
   ```powershell
   cd java-api
   ```
2. Build the application using Maven:
   ```powershell
   mvn clean package -DskipTests
   ```
   This generates `target/java-api-0.0.1-SNAPSHOT.jar`.

### 2. Containerization
1. Create a `.dockerignore` file to exclude unnecessary files (see `.dockerignore` in the project).
2. Build the Docker image:
   ```powershell
   docker build -t java-api:0.0.1-SNAPSHOT .
   ```
3. Test the image locally:
   ```powershell
   docker run -p 8080:8080 java-api:0.0.1-SNAPSHOT
   Invoke-RestMethod -Uri http://localhost:8080/health
   Invoke-RestMethod -Uri http://localhost:8080/api/users
   ```
<img width="1477" height="832" alt="image" src="https://github.com/user-attachments/assets/b07753e4-61de-4b56-b40c-ab2d73dc170a" />

### 3. Push to Google Artifact Registry
<img width="1528" height="662" alt="image" src="https://github.com/user-attachments/assets/190b0741-c179-4b53-b8a9-d9164951f342" />

1. Set environment variables:
   ```powershell
   $env:PROJECT_ID = "betbazar-ops"
   $env:REGION = "us-central1"
   $env:REPOSITORY_NAME = "java-api-repo-nadun"
   ```
2. Enable Artifact Registry API:
   ```powershell
   gcloud services enable artifactregistry.googleapis.com --project=$env:PROJECT_ID
   ```
3. Create the repository:
   ```powershell
   gcloud artifacts repositories create $env:REPOSITORY_NAME `
     --repository-format=docker `
     --location=$env:REGION `
     --project=$env:PROJECT_ID
   ```
4. Configure Docker authentication:
   ```powershell
   gcloud auth configure-docker $env:REGION-docker.pkg.dev
   ```
5. Tag and push the image:
   ```powershell
   docker tag java-api:0.0.1-SNAPSHOT "$env:REGION-docker.pkg.dev/$env:PROJECT_ID/$env:REPOSITORY_NAME/java-api:0.0.1-SNAPSHOT"
   docker push "$env:REGION-docker.pkg.dev/$env:PROJECT_ID/$env:REPOSITORY_NAME/java-api:0.0.1-SNAPSHOT"
   ```

### 4. Kubernetes Deployment
1. Configure `kubectl` for the GKE cluster:
   ```powershell
   gcloud container clusters get-credentials java-api-cluster-nadun --zone us-central1-a --project $env:PROJECT_ID
   ```
   <img width="1613" height="817" alt="image" src="https://github.com/user-attachments/assets/867c66c1-9d39-4129-b506-95d576f69f4f" />

2. Set the namespace environment variable:
   ```powershell
   $env:NAMESPACE = "java-api-ns-nadun"
   ```
3. Apply Kubernetes manifests:
   ```powershell
   kubectl apply -f k8s/
   ```
   This deploys:
   - Namespace: `java-api-ns-nadun`
   - ConfigMap: `java-api-config` (Spring Boot settings)
   - Secret: `java-api-secret` (sensitive data)
   - Deployment: `java-api-deployment` (3 replicas, non-root user)
   - Service: `java-api-service` (ClusterIP, port 80)
   - HPA: `java-api-hpa` (scales 3–10 replicas based on CPU/memory)

4. Verify resources:
   ```powershell
   kubectl get all -n $env:NAMESPACE
   ```

### 5. Configure Ingress
<img width="1547" height="660" alt="image" src="https://github.com/user-attachments/assets/1a632a43-bd22-486f-8667-ca401a75ca61" />

1. Install NGINX Ingress Controller:
   ```powershell
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```
2. Install cert-manager for TLS:
   ```powershell
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
   ```
3. Apply the ClusterIssuer and Certificate:
   ```powershell
   kubectl apply -f k8s/letsencrypt-prod.yaml
   kubectl apply -f k8s/07-certificate.yaml
   ```
4. Apply the Ingress:
   ```powershell
   kubectl apply -f k8s/08-ingress.yaml
   ```
5. Get the Ingress external IP:
   ```powershell
   kubectl get svc -n ingress-nginx
   ```
<img width="1617" height="842" alt="image" src="https://github.com/user-attachments/assets/2b8a0a3e-12e4-42f1-9059-0c2effb18551" />

6. Update DNS to point `api.nadunwansooriya.online` to the Ingress controller’s `EXTERNAL-IP` (A record).
<img width="1593" height="840" alt="image" src="https://github.com/user-attachments/assets/921a3f98-e27d-425b-9639-b552b8d2d6a9" />

### 6. Testing
1. Verify resources:
   ```powershell
   kubectl get all -n $env:NAMESPACE
   kubectl get ingress -n $env:NAMESPACE
   ```
2. Test locally via port-forwarding:
   ```powershell
   kubectl port-forward service/java-api-service 8080:80 -n $env:NAMESPACE
   Invoke-RestMethod -Uri http://localhost:8080/health
   Invoke-RestMethod -Uri http://localhost:8080/api/users
   ```
3. Test via Ingress:
   ```powershell
   Invoke-RestMethod -Uri https://api.nadunwansooriya.online/health
   Invoke-RestMethod -Uri https://api.nadunwansooriya.online/api/users
   ```
<img width="1017" height="523" alt="image" src="https://github.com/user-attachments/assets/7268ec4d-75e3-41b1-88a4-45d7a9ed5a2a" />

### 7. Monitoring
1. Enable Prometheus metrics in the ConfigMap (`k8s/02-configmap.yaml`):
   ```properties
   management.endpoints.web.exposure.include=health,info,metrics,prometheus
   management.endpoint.prometheus.enabled=true
   ```
   Re-apply and restart:
   ```powershell
   kubectl apply -f k8s/02-configmap.yaml
   kubectl rollout restart deployment java-api-deployment -n $env:NAMESPACE
   ```
2. Access Grafana (if set up in `monitoring-nadun` namespace):
   <img width="1668" height="902" alt="image" src="https://github.com/user-attachments/assets/0f75fd63-b0f5-4f09-ba5a-4d32af4c95b4" />

   ```powershell
   kubectl get pods -n monitoring-nadun -l app.kubernetes.io/name=grafana
   kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring-nadun
   ```
   Open `http://localhost:3000` (default credentials: `admin`/`prom-operator`).

4. Run the monitoring script:
   ```powershell
   .\scripts\monitor.sh
   ```
   <img width="970" height="617" alt="image" src="https://github.com/user-attachments/assets/f8a2b4ab-a801-4eb7-98c7-165883d38d17" />

