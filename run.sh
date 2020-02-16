#!/bin/bash
kubectl apply -f atlas-m10-replicaset.yml
kubectl apply -f atlas-m20-replicaset.yml
kubectl apply -f atlas-m30-replicaset.yml
