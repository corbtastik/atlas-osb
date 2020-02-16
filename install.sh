#!/bin/bash
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install catalog svc-cat/catalog --namespace catalog

kubectl apply -f atlas-osb-deployment.yml
