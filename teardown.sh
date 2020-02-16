#!/bin/bash
kubectl -n atlas delete serviceinstances --all
kubectl delete -n atlas service/atlas-osb
kubectl delete -n atlas deployment.apps/atlas-osb
helm uninstall catalog -n catalog
kubectl delete ns catalog
kubectl delete ns atlas
