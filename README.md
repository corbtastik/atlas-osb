# Atlas OSB on K8s

A quick sample of deploying Atlas OSB so we can provision MongoDB databases in Atlas from K8s.

1. You'll need a Kubernetes Cluster (minikube should work)
1. An account on [Atlas](https://cloud.mongodb.com)
1. Check off on prerequisites listed [here](https://docs.mongodb.com/atlas-open-service-broker/current/installation/).

The sample is broken down into 3 parts.

1. Install the Atlas OSB and Service Catalog - install.sh
1. Configure Atlas OSB with Atlas API Key - configure.sh
1. Deploy MongoDB databases on Atlas with the OSB - run.sh
