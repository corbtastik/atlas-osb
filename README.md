# Atlas OSB and MongoDB

A short sample using the Atlas Open Service Broker on K8s to provision MongoDB databases in Atlas.

K8s automation and "always on" [Atlas](https://www.mongodb.com/cloud/atlas) :sunglasses:

Whatcha need

1. A Kubernetes Cluster (minikube should work)
1. An account on [Atlas](https://cloud.mongodb.com)
1. Tools - kubectl, helm, svcat - See [Downloads for versions](#downloads)

The sample is broken down into 5 parts.

1. [Start K8s cluster](#start-k8s-cluster)
1. [Deploy Service Catalog and Atlas OSB](#deploy-service-catalog-and-atlas-osb)
1. [Configure Atlas OSB with API Key](#configure-atlas-osb-with-api-key)
1. [Provision MongoDB Service Instances on Atlas](#provision-mongodb-service-instances-on-atlas)
1. [Connect to MongoDB Service Instance](#connect-to-mongodb-service-instance)

## Start K8s cluster

Configure cpu, memory and vm-driver for your tastes and start Minikube.

```bash
# start.sh
minikube start --vm-driver=virtualbox \
  --cpus=4 \
  --memory=8192 \
  --kubernetes-version=1.15.10
```

## Deploy Service Catalog and Atlas OSB

Run :runner: `./install.sh`

```bash
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
```

Wait until you :eyes: the Atlas OSB Pod running in the `atlas` namespace before continuing.

## Configure Atlas OSB with API Key

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

Run :runner: `./configure.sh`

To configure your API Key with the Atlas OSB and register it as a namespace scoped Service Broker.

```bash
# configure.sh
kubectl apply -f atlas-apikey.yml
kubectl apply -f atlas-osb-servicecatalog.yml
```

At this point the Atlas OSB

* Is registered as a Service Broker in the `atlas` namespace
* Configured to call Atlas API

```bash
# internal dns of Service Broker, broker-name.namespace
kubectl -n atlas get servicebroker
NAME        URL                      STATUS   AGE
atlas-osb   http://atlas-osb.atlas   Ready    25s

# can call Atlas and get Service Plans
kubectl -n atlas get serviceplans
# using servicecatalog cli
svcat marketplace -n atlas
 CLASS                  PLANS       DESCRIPTION             
+----------------------+-----------+----------------------------------+
 mongodb-atlas-aws      M10         Atlas cluster hosted on "AWS"     
                        M100                                          
                        M140                                      
```

## Provision MongoDB Service Instances on Atlas

Now we're ready to bake :cake: some MongoDB with the Atlas OSB.  Let's provision an M10 on each provider.

Make sure to configure each Service Instance with a valid `serviceClassExternalName` and `servicePlanExternalName` from `svcat marketplace -n atlas`.

Atlas regionName(s) are named different than public cloud providers.

* Mappings
  * [AWS](https://docs.atlas.mongodb.com/reference/amazon-aws/)
  * [GCP](https://docs.atlas.mongodb.com/reference/google-gcp/)
  * [Azure](https://docs.atlas.mongodb.com/reference/microsoft-azure/)

The full list of supported cluster properties is given in the [Create Cluster request body of the Atlas API](https://docs.atlas.mongodb.com/reference/api/clusters-create-one/#request-body-parameters).

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

Run :runner: `./provision.sh`

```bash
# provision.sh
kubectl apply -f cluster-configs/atlas-m10-aws.yml
kubectl apply -f cluster-configs/atlas-m10-azure.yml
kubectl apply -f cluster-configs/atlas-m10-gcp.yml
```

You should :eyes: 3 M10s starting in Atlas as well as kubectl.

```bash
kubectl -n atlas get serviceinstances        
NAME              CLASS                              PLAN   STATUS         AGE
atlas-m10-aws     ServiceClass/mongodb-atlas-aws     M10    Provisioning   37s
atlas-m10-azure   ServiceClass/mongodb-atlas-azure   M10    Provisioning   37s
atlas-m10-gcp     ServiceClass/mongodb-atlas-gcp     M10    Provisioning   37s
# detailed info
kubectl -n atlas describe serviceinstances
```

## Connect to MongoDB Service Instance

At this point you should have 3 M10(s) running and now it's time to connect via a Service Binding.

For convenience there's an sample ServiceBinding `atlas-servicebinding.yml` for the M10 AWS Service Instance, pre-configured with Service Instance user `atlas_user1`.

## TODO - Work-in-progress

Pick up here :truck:

## Teardown

Save a tree...run `./teardown.sh` to delete all Service Instances and uninstall the Atlas OSB.

## Downloads

To run this sample you'll need each of the tools below, pay close attention to the versions sited as there are incompatibilities with certain mixes of these tools.

*Note* - We'll be using K8s v1.15.x, ensure kubectl and K8s cluster match.

1. [Minikube v1.6.x](https://minikube.sigs.k8s.io/docs/start/) - `start.sh` is configured for K8s v1.15.10
1. [Kubectl v1.15.10](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [Helm v3.1.1](https://helm.sh/docs/intro/install/)
1. [Service Catalog CLI - svcat  v0.3.0-beta.x](https://github.com/kubernetes-sigs/service-catalog/blob/master/docs/install.md#installing-the-service-catalog-cli)

## References

1. [Atlas OSB on Github](https://github.com/mongodb/mongodb-atlas-service-broker)
1. [Atlas OSB Install Docs](https://docs.mongodb.com/atlas-open-service-broker/current/installation/)
1. [Atlas API](https://docs.atlas.mongodb.com/reference/api-resources/)
1. [Kubernetes, Helm and Service Catalog Chart wackiness](https://stackoverflow.com/questions/58481850/no-matches-for-kind-deployment-in-version-extensions-v1beta1)
