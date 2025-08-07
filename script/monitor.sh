#!/bin/bash
# scripts/monitor.sh
echo "=== Java API Monitoring ==="
echo "Namespace: java-api-ns-nadun"
echo

echo "Pods Status:"
kubectl get pods -n java-api-ns-nadun
echo -e "\nService Status:"
kubectl get svc -n java-api-ns-nadun
echo -e "\nIngress Status:"
kubectl get ingress -n java-api-ns-nadun
echo -e "\nHPA Status:"
kubectl get hpa -n java-api-ns-nadun
echo -e "\nRecent Events:"
kubectl get events -n java-api-ns-nadun --sort-by='lastTimestamp' | tail -10

read -p "Press [Enter] key to exit..."