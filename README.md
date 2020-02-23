# Atlas OSB and MongoDB

A short sample using the Atlas Open Service Broker on K8s to provision MongoDB databases in Atlas.

K8s automation and "always on" [Atlas](https://www.mongodb.com/cloud/atlas) :sunglasses:

Whatcha need

1. A Kubernetes Cluster (minikube should work)
1. An account on [Atlas](https://cloud.mongodb.com)
1. kubectl, helm, svcat - See [Downloads](#/downloads)

The sample is broken down into 3 parts.

1. Deploy Service Catalog and Atlas OSB
1. Configure Atlas OSB
1. Provision MongoDB Service Instances on Atlas

## Deploy Service Catalog and Atlas OSB

Run `./install.sh`

```bash
#!/bin/bash
# install.sh
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

## Configure Atlas OSB

Create an API Key for the Atlas OSB to use.

* Atlas > Project > Access Management > API Key
* Whitelist your IP (on full K8s whitelist worker nodes)
* Your ProjectId is @ Atlas > Project > Settings
* Configure the `PRIVATE-KEY`, `PUBLIC-KEY` and `PROJECT-ID` in `atlas-apikey.yml`.


```yaml
# atlas-apikey.yml
apiVersion: v1
kind: Secret
metadata:
  name: atlas-osb-auth
  namespace: atlas
type: Opaque
stringData:
  username: PUBLIC-KEY@PROJECT-ID #replace
  password: PRIVATE-KEY           #replace
```

Once that's in-place...

Run `./configure.sh`

```bash
#!/bin/bash
# configure.sh
kubectl apply -f atlas-apikey.yml
kubectl apply -f atlas-osb-servicecatalog.yml
```

At this point the Atlas OSB

* Is registered as a Service Broker in K8s
* Can call Atlas

```bash
# internal dns of Service Broker, broker-name.namespace
kubectl -n atlas get servicebroker
NAME        URL                      STATUS   AGE
atlas-osb   http://atlas-osb.atlas   Ready    25s

# can call Atlas and get Service Plans
kubectl -n atlas get serviceplans
# using servicecatalog cli
svcat marketplace -n atlas
        CLASS             PLANS               DESCRIPTION             
+----------------------+-----------+----------------------------------+
 mongodb-atlas-aws      M10         Atlas cluster hosted on "AWS"     
                        M100                                          
                        M140                                      
```

## Provision MongoDB Service Instances on Atlas

Now we're ready to bake some MongoDB with the Atlas OSB :cake:.  Let's provision an m10 on each provider.

Make sure to configure each Service Instance with a valid `serviceClassExternalName` and `servicePlanExternalName` from `svcat marketplace -n atlas`.

Atlas Region Mappings
* [AWS](https://docs.atlas.mongodb.com/reference/amazon-aws/)
* [GCP](https://docs.atlas.mongodb.com/reference/google-gcp/)
* [Azure](https://docs.atlas.mongodb.com/reference/microsoft-azure/)

```yaml
# atlas-m10-gcp.yml ServiceInstance
apiVersion: servicecatalog.k8s.io/v1beta1
kind: ServiceInstance
metadata:
  name: atlas-m10-gcp
  namespace: atlas
spec:
  serviceClassExternalName: mongodb-atlas-gcp
  servicePlanExternalName: M10
  parameters:
    cluster:
      providerSettings:
        regionName: CENTRAL_US
```

Run `./provision.sh`

```bash
#!/bin/bash
# provision.sh
kubectl apply -f atlas-m10-aws.yml
kubectl apply -f atlas-m10-azure.yml
kubectl apply -f atlas-m10-gcp.yml
```

You should see 3 m10s starting in Atlas :eyes:

```bash
kubectl -n atlas get serviceinstances        
NAME              CLASS                              PLAN   STATUS         AGE
atlas-m10-aws     ServiceClass/mongodb-atlas-aws     M10    Provisioning   37s
atlas-m10-azure   ServiceClass/mongodb-atlas-azure   M10    Provisioning   37s
atlas-m10-gcp     ServiceClass/mongodb-atlas-gcp     M10    Provisioning   37s
```

## Teardown

Save a tree...run `./teardown.sh` to delete all Service Instances and uninstall the Atlas OSB.

## References

1. [Atlas OSB Install Docs](https://docs.mongodb.com/atlas-open-service-broker/current/installation/)
1. [Kubernetes, Helm and Service Catalog Chart wackiness](https://stackoverflow.com/questions/58481850/no-matches-for-kind-deployment-in-version-extensions-v1beta1)


## Downloads

1. [Minikube](https://minikube.sigs.k8s.io/docs/start/)
1. [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [Helm](https://helm.sh/docs/intro/install/)
1. [Service Catalog CLI - svcat](https://github.com/kubernetes-sigs/service-catalog/blob/master/docs/install.md#installing-the-service-catalog-cli)
