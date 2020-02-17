# Atlas OSB and MongoDB

A short sample using the Atlas Open Service Broker on K8s to provision MongoDB databases in Atlas.

K8s automation and "always on" [Atlas](https://www.mongodb.com/cloud/atlas) :sunglasses:

Whatcha need

1. A Kubernetes Cluster (minikube should work)
1. An account on [Atlas](https://cloud.mongodb.com)
1. kubectl, helm, svcat - See [Downloads](#/downloads)

The sample is broken down into 3 parts.

1. Install Service Catalog and the Atlas OSB
1. Configure Atlas OSB with an Atlas API Key
1. Provision MongoDB Service Instances on Atlas

## Install Service Catalog and the Atlas OSB

`./install.sh`

```bash
#!/bin/bash
# service catalog
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
```

## Configure Atlas OSB with an Atlas API Key

Create an API Key for the Atlas OSB to use.

* Atlas > Project > Access Management > API Key
* Whitelist your IP (on full K8s whitelist worker nodes)

<img src="/assets/apikey.png" width="75%">  

---

Configure the `PRIVATE-KEY`, `PUBLIC-KEY` and `PROJECT-ID` in `atlas-apikey.yml`.
* Your ProjectId is @ Atlas > Project > Settings.

```yaml
# atlas-apikey.yml
apiVersion: v1
kind: Secret
metadata:
  name: atlas-osb-auth
  namespace: atlas
type: Opaque
stringData:
  username: PUBLIC-KEY@PROJECT-ID
  password: PRIVATE-KEY
```

Once that's in-place run

`./configure.sh`

```bash
#!/bin/bash
kubectl apply -f atlas-apikey.yml
kubectl apply -f atlas-osb-servicecatalog.yml
```

The Atlas OSB is configured to

## References

1. [Atlas OSB Install Docs](https://docs.mongodb.com/atlas-open-service-broker/current/installation/)


## Downloads

1. [Minikube](https://minikube.sigs.k8s.io/docs/start/)
1. [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [Helm](https://helm.sh/docs/intro/install/)
1. [Service Catalog CLI - svcat](https://github.com/kubernetes-sigs/service-catalog/blob/master/docs/install.md#installing-the-service-catalog-cli)
