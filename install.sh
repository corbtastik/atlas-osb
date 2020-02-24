#!/bin/bash
# service catalog
kubectl create ns catalog
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install catalog svc-cat/catalog --namespace catalog
# atlas osb
kubectl create ns atlas
kubectl apply -f atlas-osb-deployment.yml
# inspect atlas-osb deployment
kubectl -n atlas get deployment atlas-osb --show-labels
kubectl -n atlas get services --show-labels
kubectl -n atlas get pods --show-labels
