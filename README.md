# Atlas OSB and MongoDB

Do you like cloud-native automation? (*I know you do, you devOps diva.*) Bespoke processes and manual provisioning gotcha a little melancholy?  Well turn that frown upside down buttercup, things are looking up :sunny:

In this sample we'll take a looksy at machining MongoDB clusters with the [Atlas Open Service Broker](https://github.com/mongodb/mongodb-atlas-service-broker) on Kubernetes.  This is one of three ways to integrate with MongoDB [Atlas](https://www.mongodb.com/cloud/atlas) to automate managing Clusters.  The other two are [Terraform](https://www.terraform.io/docs/providers/mongodbatlas/index.html) and the native [Atlas API](https://docs.atlas.mongodb.com/api/).  We'll grok those in another post on-down the road.

Whatcha need

1. A Kubernetes Cluster (Minikube should work)
1. An account on [Atlas](https://cloud.mongodb.com)
1. Tools - kubectl, helm, svcat - See [Downloads for versions](#downloads)

The sample is broken down into 6 parts.

1. [Start K8s cluster](#start-k8s-cluster)
1. [Deploy Service Catalog](#deploy-service-catalog)
1. [Configure Atlas API Key](#configure-atlas-api-key)
1. [Deploy Atlas OSB](#deploy-atlas-osb)
1. [Provision MongoDB Service Instances on Atlas](#provision-mongodb-service-instances-on-atlas)
1. [Connect to MongoDB Service Instance](#connect-to-mongodb-service-instance)

## Start K8s cluster

Feel free to use K8s on the public cloud or simply use Minikube which is perfect for this sample.

**Note:** If you're willing to pay a little money then I'd highly recommend buying a license for [VMware Fusion](https://www.vmware.com/products/fusion/fusion-evaluation.html) which will vastly improve your local devOps experience running VMs.  Virtualbox will work but as one great devOps professional said "Virtualbox is for little kids and VMware Fusion is for bigger kids with a job"...I'm paraphrasing but that's close.

Configure cpu, memory and vm-driver for your tastes and start Minikube.

```bash
# start.sh
# use --vm-driver=vmware if you have VMware Fusion installed
minikube start --vm-driver=virtualbox \
  --cpus=4 \
  --memory=8192 \
  --kubernetes-version=1.15.10
```

## Deploy Service Catalog

Our K8s Cluster needs a Service Catalog installed so we can thumb through it for MongoDB Atlas plans in a bit.  Run the commands below to install a Service Catalog using Helm...note we're deploying it into the catalog namespace.

[Service Catalog install docs](https://kubernetes.io/docs/tasks/service-catalog/install-service-catalog-using-helm/)

```bash
# service catalog
kubectl create ns catalog
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install catalog svc-cat/catalog --namespace catalog
```

## Configure Atlas API Key

Ok let's get a bit of manual config taken care of.  Head over to Atlas and generate an API Key for the Atlas Service Broker to use.

* Atlas > Project > Access Management > API Key
* Whitelist your IP on the API Key (on full K8s whitelist each worker node)
* Your ProjectId is @ Atlas > Project > Settings
* Configure the `PRIVATE-KEY`, `PUBLIC-KEY` and `PROJECT-ID` in `atlas-apikey.yml`.


```yaml
# atlas-apikey.yml
# Atlas API Key as a K8s Secret
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

Once that's in-place we're cooking with corn oil :corn:...(hey that's just corny).

## Deploy Atlas OSB

Run :runner: the `./install.sh` script to deploy

1. The Atlas OSB application
1. An internal ClusterIP exposing ^^^ on port 4000 internally
1. A Secret that contains the before mentioned Atlas API Key
1. Last but not least the Service Broker for the Catalog

```bash
# install.sh
# atlas osb
kubectl create ns atlas
kubectl apply -f atlas-api-key.yml
kubectl apply -f atlas-osb-deployment.yml
# inspect atlas-osb deployment
kubectl -n atlas get deployment atlas-osb --show-labels
kubectl -n atlas get services --show-labels
kubectl -n atlas get pods --show-labels
```

Wait until you :eyes: the Atlas OSB Pod running in the `atlas` namespace before continuing.

Grok the Broker.

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

At this point the Atlas OSB is ready to do some mongo baking :cake:...sahweet.  Let's provision an M10 on each provider.

Make sure to configure each Service Instance with valid config from `svcat marketplace -n atlas`.

* `serviceClassExternalName` - mongodb-atlas-aws...gpc, azure
* `servicePlanExternalName` - atlas plan name, M10...etc.

**Note:** Atlas regionName(s) are named different than public cloud providers, use the links below to get correct names.

* [AWS](https://docs.atlas.mongodb.com/reference/amazon-aws/)
* [GCP](https://docs.atlas.mongodb.com/reference/google-gcp/)
* [Azure](https://docs.atlas.mongodb.com/reference/microsoft-azure/)

For this sample we're keeping the cluster configs pretty basic, the full list of supported cluster properties is given in the [Create Cluster request body of the Atlas API](https://docs.atlas.mongodb.com/reference/api/clusters-create-one/#request-body-parameters).

Sample Service Instance deployment.

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
      mongoDBMajorVersion: 4.2
      providerSettings:
        regionName: CENTRAL_US
```

Deploy each Service Instance and kickback with a snack :doughnut: for several minutes while Atlas brings our clusters online.

```bash
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

At this point you should have 3 M10(s) running and now it's time to connect via a Service Binding.  In order to do that we need to perform the following steps.

1. Create Service Bindings for each cluster user
1. Retrieve the Atlas connection deets for each user
1. Connect to the MongoDB cluster with the mongo shell, Compass or an app

### Create Service Bindings

For convenience there's sample ServiceBindings in `./cluster-configs` for each M10 Service Instance, pre-configured with a Service Instance user...for example `atlas-m10-aws-user1`.

```bash
kubectl apply -f ./cluster-configs/atlas-m10-aws-servicebinding.yml
kubectl apply -f ./cluster-configs/atlas-m10-azure-servicebinding.yml
kubectl apply -f ./cluster-configs/atlas-m10-gcp-servicebinding.yml

# view service bindings with kubectl
kubectl -n atlas get servicebindings
kubectl -n atlas describe servicebindings

# view details of service bindings with svcat, notice "Secret Data"
svcat describe binding atlas-m10-gcp-user1 -n atlas
```

### Retrieve Atlas Connection Details

Each Service Binding includes a [base64 encoded Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) containing the Cluster uri, username and password.  You can view the encoded secret using kubectl.

```bash
kubectl get secret atlas-m10-gcp-user1 -n atlas -o yaml

apiVersion: v1
data:
  password: TzAxVXcxUGRpMlFUOUlaMTNjRFV3THJKdXd2UzJGeWJwazBKV2tCNWJkVT0=
  uri: bW9uZ29kYitzcnY6Ly9hZGExNjA4Ny02MTUzLTExZWEtOWY4OC1uZWdhZS5nY3AubW9uZ29kYi5uZXQ=
  username: NTAwMGZkMTktNjE1OC0xMWVhLTlmODgtMDI0MmFjMTEwMDA1
kind: Secret
metadata:
  name: atlas-m10-gcp-user1
  namespace: atlas
type: Opaque
```

### Connect to MongoDB

We'll need to decode the Secret before we can use it to connect to our running MongoDB cluster.  Most Operating Systems include a `base64` command that can be used to decode the Secret.

```bash
# decode uri
echo 'bW9uZ29kYitzcnY6Ly9hZGExNjA4Ny02MTUzLTExZWEtOWY4OC1uZWdhZS5nY3AubW9uZ29kYi5uZXQ=' | base64 --decode
# decode username
echo 'NTAwMGZkMTktNjE1OC0xMWVhLTlmODgtMDI0MmFjMTEwMDA1' | base64 --decode
# decode password
echo 'TzAxVXcxUGRpMlFUOUlaMTNjRFV3THJKdXd2UzJGeWJwazBKV2tCNWJkVT0=' | base64 --decode
```

Now we have everything required to connect with the Mongo Shell, Compass or an App.

```bash
mongo mongodb+srv://ada16087-6153-11ea-9f88-negae.gcp.mongodb.net --username 5000fd19-6158-11ea-9f88-0242ac110005
MongoDB shell version v4.2.3
Enter password:
connecting to: mongodb://ada16087-6153-11ea-9f8...blah blah blah
MongoDB server version: 4.2.3
MongoDB Enterprise shard-0:PRIMARY> use todosdb
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Start K8s Cluster", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Deploy Service Catalog", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Configure Atlas API Key", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Deploy Atlas OSB", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Provision MongoDB Service Instances on Atlas", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.insertOne({title: "Connect to MongoDB Service Instance", complete: true})
MongoDB Enterprise shard-0:PRIMARY> db.todos.find({}, {_id:0})
{ "title" : "Start K8s Cluster", "complete" : true }
{ "title" : "Deploy Service Catalog", "complete" : true }
{ "title" : "Configure Atlas API Key", "complete" : true }
{ "title" : "Deploy Atlas OSB", "complete" : true }
{ "title" : "Provision MongoDB Service Instances on Atlas", "complete" : true }
{ "title" : "Connect to MongoDB Service Instance", "complete" : true }
```

## That's a wrap

That's a wrap folks...We're literally just scratching the surface but hopefully you can see how useful the combo of Atlas and K8s can be.  Even with this Playskool example we were able to automate MongoDB provisioning across Cloud Providers which without Atlas would be no small task.  

Atlas is machinable MongoDB goodness...keep calm and Mongo On :sunglasses:.

## Uninstall

Save a :evergreen_tree:...run `./uninstall.sh` to delete all Service Instances, remove the Atlas OSB and Service Catalog.

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
