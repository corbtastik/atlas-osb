#!/bin/bash
# atlas osb
kubectl create ns atlas
kubectl apply -f atlas-apikey.yml
kubectl apply -f atlas-osb-deployment.yml
# inspect atlas-osb deployment
kubectl -n atlas get deployment atlas-osb --show-labels
kubectl -n atlas get services --show-labels
kubectl -n atlas get pods --show-labels
