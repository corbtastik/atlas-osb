#!/bin/bash
minikube start --vm-driver=virtualbox \
  --cpus=4 \
  --memory=8192 \
  --kubernetes-version=1.15.10
