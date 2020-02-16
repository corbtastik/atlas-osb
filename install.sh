#!/bin/bash
kubectl create ns catalog
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install catalog svc-cat/catalog --namespace catalog
# atlas osb
kubectl create ns atlas
kubectl apply -f atlas-osb-deployment.yml
# inspect atlas-osb deployment
kubectl -n atlas describe deployment atlas-osb
kubectl -n atlas describe pod atlas-osb
kubectl -n atlas describe service atlas-osb
kubectl -n atlas get services --show-labels
kubectl -n atlas get pods --show-labels
