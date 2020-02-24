#!/bin/bash
kubectl apply -f cluster-configs/atlas-m10-aws.yml
kubectl apply -f cluster-configs/atlas-m10-azure.yml
kubectl apply -f cluster-configs/atlas-m10-gcp.yml
