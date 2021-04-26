# Kubeflow PoC (for AWS)

This repo contains a poc effort for Kubeflow up on AWS EKS. Ideally, it is to help explore the capabilities of kubeflow in regards to the larger Babylon effort.

The actual kubeflow instructions are available at [Install Kubeflow on AWS](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/). Another good documentation page is [End-to-End Kubeflow on AWS](https://www.kubeflow.org/docs/distributions/aws/aws-e2e/)


### Prerequisites
--------------------------------------------
* kubectl - *(official CLI for generic Kubernetes)*
    * [Install kubectl - OSX/Linux/Windows](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
* AWS CLI - *(official CLI for AWS)*
    * [Install/Upgrade AWS CLI - OSX](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-cmd-all-users)
    * [Install AWS CLI - Linux](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install)
    * [Upgrade AWS CLI - Linux](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-upgrade)
* AWS IAM Authenticator - *(helper tool to provide authentication to Kube cluster)*
    * Linux Installation - v1.19.6
        * `curl -o /tmp/aws-iam-authenticator "https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator"`
        * `sudo mv /tmp/aws-iam-authenticator /usr/local/bin`
        * `sudo chmod +x /usr/local/bin/aws-iam-authenticator`
        * `aws-iam-authenticator help`
    * OSX and Windows Installation 
        * [Install AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
* eksctl - *(official CLI for Amazon EKS)*
    * [Install/Upgrade eksctl - OSX/Linux/Windows](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
* Helm - *(helpful Package Manager for Kubernetes)*
    * [Install](https://docs.aws.amazon.com/eks/latest/userguide/helm.html)
* kfctl - *(official CLI for Kubeflow)*
    * OSX Installation - v1.2.0
        * `curl --silent --location "https://github.com/kubeflow/kfctl/releases/download/v1.2.0/kfctl_v1.2.0-0-gbc038f9_darwin.tar.gz" | tar xz -C /tmp`
        * `sudo mv /tmp/kfctl /usr/local/bin`
        * `kfctl version`
    * Linux Installation - v1.2.0
        * `curl --silent --location "https://github.com/kubeflow/kfctl/releases/download/v1.2.0/kfctl_v1.2.0-0-gbc038f9_linux.tar.gz" | tar xz -C /tmp`
        * `sudo mv /tmp/kfctl /usr/local/bin`
        * `kfctl version`

### Install Instructions
--------------------------------------------
Before you being with Kubeflow, you must have a cluster up and running with AWS EKS.  
Use the `eksctl` tool to create a specific cluster up on AWS for your needs.  
Name it what you want and take note of that name as you will need it with `kfctl`.  
## Step 1 - Configure `awscli` and `eksctl`
Define your key and secret in `~/.aws/credentials`
```
[default]
aws_access_key_id = SOMETHING
aws_secret_access_key = SOMETHINGLONGER
```
Define your profile information (AWS Organization) in `~/.aws/config`.
```
[default]
region = us-west-2
output = json

[profile bl-babylon]
role_arn = arn:aws:iam::562046374233:role/BabylonOrgAccountAccessRole
source_profile = default
```
***A sysadmin should have already given your AWS IAM (i.e. paloul, mshirdel) the appropriate  
policy to be able to assume the Babylon sub-account role, `BabylonOrgAccountAccessRole`.***

You must execute `awscli` or `eksctl` commands while assuming the correct role in order  
to deploy the cluster under the right account. This is done with either the `--profile`  
option or the use of an environment variable `AWS_PROFILE`, i.e. `export AWS_PROFILE=bl-profile1`,  
before executing any commands. Visit [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html#using-profiles) for information.

Execute the following command to verify you configured `awscli` and `eksctl` correctly:
```
╰─❯ eksctl get cluster --verbose 4 --profile bl-babylon
[▶]  role ARN for the current session is "arn:aws:sts::562046374233:assumed-role/BabylonOrgAccountAccessRole/1618011239640991900"
[ℹ]  eksctl version 0.44.0
[ℹ]  using region us-west-2
No clusters found
```
You can verify you are using the right profile with the following:
```
aws sts get-caller-identity
```
You should receive the following JSON listing the use of the `BabylonOrgAccountAccessRole` role.
```
{
    "UserId": "AROAYFXETCFMU6ZHKQUOR:botocore-session-1618010824",
    "Account": "562046374233",
    "Arn": "arn:aws:sts::562046374233:assumed-role/BabylonOrgAccountAccessRole/botocore-session-1618010824"
}
```  
----
## Step 2 - Create EKS Cluster - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
Execute the following `eksctl` command to create a cluster under the AWS Babylon account. You  
should be in the same directory as the file `aws-eks-cluster.yaml`. 
```
eksctl create cluster -f aws-eks-cluster-spec.yaml --profile bl-babylon
```
This command will take several minutes as `eksctl` creates the entire stack with  
supporting services inside AWS, i.e. VPC, Subnets, Security Groups, Route Tables,  
in addition to the cluster itself. Once completed you should see the following:
```
[✓]  EKS cluster "babylon-1" in "us-west-2" region is ready
```
With nothing else running on the cluster you can check `kubectl` and see similar output:  
```
╰─❯ kubectl get nodes
NAME                                           STATUS   ROLES    AGE   VERSION
ip-192-168-2-226.us-west-2.compute.internal    Ready    <none>   17m   v1.19.6-eks-49a6c0
ip-192-168-26-228.us-west-2.compute.internal   Ready    <none>   17m   v1.19.6-eks-49a6c0

╰─❯ kubectl get pods -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
aws-node-2ssm5             1/1     Running   0          19m
aws-node-xj5sb             1/1     Running   0          19m
coredns-6548845887-fg74h   1/1     Running   0          25m
coredns-6548845887-vlzff   1/1     Running   0          25m
kube-proxy-hjgd5           1/1     Running   0          19m
kube-proxy-jm2m9           1/1     Running   0          19m
```
### <u>Delete the EKS Cluster When Not Needed</u>
One node group starts up a min 2 EC2 machines that charge by the hour. The other node groups  
are setup to scale down to 0 and only ramp up when pods are needed. In order to avoid being  
charged while not in use please use the following command to delete your cluster:
```
eksctl delete cluster -f aws-eks-cluster-spec.yaml --profile bl-babylon
```  
### <u>Kubernetes Cluster Autoscaler</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)
We now need to also install the Kubernetes Cluster Autoscaler in order to support the  
capability to scale up our underlying EC2 nodes. Execute the following:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```
Open the Cluster Autoscaler deployment configuration for editing: 
```
kubectl edit deployment cluster-autoscaler -n kube-system
```
* Find the `node-group-auto-discovery` property in the autoscaler command deployment flag section  
and add your cluster name to the end, i.e. 
`--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>`.
* In the same section as the node-group-auto-discovery, add: `- --balance-similar-node-groups`
* In the same section as the node-group-auto-discovery, add: `- --skip-nodes-with-system-pods=false`
* Find the `image` property and set the right image version to match your Kubernetes cluster, i.e. `image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.19.1`. Version 1.19 is defined in the file  
`aws-eks-cluster-spec.yaml`. If you have changed the version there, you should change it here as well.

Verify that the Cluster Autoscaler was successfully launched:
```
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```

### <u>AWS Load Balancer Controller</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
AWS Load Balancer Controller manages AWS Elastic Load Balancers for a Kubernetes cluster. The controller  
is a `kube-system` namespace service that provisions:

* An AWS Application Load Balancer (ALB) when you create a Kubernetes Ingress.
* An AWS Network Load Balancer (NLB) when you create a Kubernetes Service of type LoadBalancer using  
IP targets on 1.18 or later Amazon EKS clusters.

More detail is at the link in the title to this section. An OIDC provider was already created by `eksctl`.  
Follow these steps:
```
# Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf. This might've already been done as it exists at the AWS account level.
curl -o elb_iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.1.3/docs/install/iam_policy.json

# Create an IAM policy using the policy downloaded in the previous step. This might've already been done as it exists at the AWS account level.
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://elb_iam_policy.json
# Take note of the policy ARN that is returned.

# Create an IAM role and annotate the Kubernetes service account named aws-load-balancer-controller in the kube-system namespace
eksctl create iamserviceaccount \
  --cluster=babylon-1 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
# eksctl will modify the existing CloudFormation for the cluster created to add this new service account

# Install cert-manager to inject certificate configuration into the webhooks.
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.1.1/cert-manager.yaml

# Download the controller specification. 
curl -o aws-lb-ctrl-v2_1_3_full.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.1.3/docs/install/v2_1_3_full.yaml

# Modify two things in the aws-lb-ctrl-v2_1_3_full.yaml file
# 1. Delete the ServiceAccount section from the specification. 
# 2. Set the --cluster-name value to your Amazon EKS cluster name in the Deployment spec section.

# Apply the file and create the controller
kubectl apply -f aws-lb-ctrl-v2_1_3_full.yaml
```
Check the created pods under the `kube-system` namespace to see if it was succesful:
```
─❯ kubectl get pods -n kube-system
NAME                                           READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-b698949bb-gmlm8   1/1     Running   0          38s
aws-node-4mk9j                                 1/1     Running   0          12m
aws-node-smm5c                                 1/1     Running   0          12m
cluster-autoscaler-778bbcdb98-mxwnv            1/1     Running   0          5m36s
coredns-559b5db75d-fjmhq                       1/1     Running   0          29m
coredns-559b5db75d-wx266                       1/1     Running   0          29m
kube-proxy-bwlph                               1/1     Running   0          12m
kube-proxy-t72lw                               1/1     Running   0          12m
```

### <u>Install the Metrics Server</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html)
The Kubernetes Metrics Server is an aggregator of resource usage data in your cluster. By default, it  
monitors CPU and Memory usage. Allows the ability to execute `kubectl top [nodes|pods]` and see metrics.
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
Verify the Metrics Server was properly installed:
```
kubectl get deployment metrics-server -n kube-system

NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           6m
```

### <u>Install the Kubernetes Dashboard UI</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)
The Dashboard allows you to view CPU and Memory metrics on all running nodes in the cluster.  
Execute on the cluster:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.5/aio/deploy/recommended.yaml

# A manifest file, `eks-admin-service-account.yaml`, has already been created that  
# defines a service account and a cluster role binding called `eks-admin`.  
# These provide you the ability to securely connect to the dashboard with  
# admin-level permissions. 

# Apply the service account and cluster role binding.
kubectl apply -f eks-admin-service-account.yaml
```
With the Dashboard deployed to your cluster and the service account created, you can connect to the dashboard  
with that service account.  

Retrieve an authentication token for the eks-admin service account. Copy the <authentication_token>  
value from the output. You will use this token to connect to the dashboard.
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

You will see the following response. The token generated can be used to login to the Dashboard.
```
Name:         eks-admin-token-b5zv4
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=eks-admin
              kubernetes.io/service-account.uid=bcfe66ac-39be-11e8-97e8-026dce96b6e8

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:      <AUTHENTICATION_TOKEN>
```
You must execute `kubectly proxy` in order to connect your `localhost` to the cluster.  
It is not a good idea and ill-advised to expose the Dashboard Admin via any external ingress means.
```
kubectl proxy
```
Now you open your browser and visit [THIS](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login). Choose **TOKEN**, pase the <AUTHENTICATION_TOKEN> output from the  
previous command into the *Token* field and choose **SIGN IN**.  

### <u>Install Spot Instance Termination Handler for Kubernetes</u> - [Additional Info](https://github.com/aws/aws-node-termination-handler)  
Since we have Spot instance nodes in the cluster, the Kubernetes control plan needs to be able to  
respond quickly and appropriately to the underlying EC2 nodes becoming unavailable, i.e. especially  
due to EC2 Spot instance interruption or recall. Spot instances cheaper, roughly 70-80% less  
than On-Demand instances, but AWS reserves the right to recall Spot to support On-Demand usage.  
Spot instances after all are just unused spare capacity offered at a lower price to spur more usage.  
This termination handler feature though applies to both Spot and On-Demand instances, as it is  
benficial to both.  

The Node Termination Handler uses a DaemonSet on each node instance. It monitors the EC2 meta-data  
service on each node to capture any interruption notices. The workflow is summarized as:  

* Identify that an instance (Spot) is being reclaimed.
* Use the 2-minute notification window to gracefully prepare the node for termination.
* Taint the node and cordon it off to prevent new pods from being placed on it.
* Drain the connections on the running pods.
* Replace the pods on remaining nodes to maintain the desired capacity.

Make sure you have Helm installed at this point in time. 
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-node-termination-handler eks/aws-node-termination-handler \
 --namespace kube-system \
 --set enableSpotInterruptionDraining="true" \
 --set enableScheduledEventDraining="true"
```  
You can view it was correctly installed with:
```
╰─❯ kubectl get daemonsets -n kube-system
NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
aws-node                       1         1         1       1            1           <none>                   25h
aws-node-termination-handler   1         1         1       1            1           kubernetes.io/os=linux   4m56s
kube-proxy                     1         1         1       1            1           <none>                   25h

╰─❯ kubectl get pods -n kube-system
NAME                                  READY   STATUS    RESTARTS   AGE
aws-node-2ssm5                        1/1     Running   0          25h
aws-node-termination-handler-4pztt    1/1     Running   0          14s
cluster-autoscaler-6fb975488f-q9522   1/1     Running   0          24h
coredns-6548845887-fg74h              1/1     Running   0          25h
coredns-6548845887-v2ch5              1/1     Running   0          24h
kube-proxy-jm2m9                      1/1     Running   0          25h
```
For reference, if necessary, you can delete the Helm package with:  
```
helm uninstall aws-node-termination-handler --namespace kube-system
```

### <u>Install the Nvidia Kubernetes Device Plugin</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html#gpu-ami)
After your GPU nodes join your cluster, you must apply the NVIDIA device plugin for Kubernetes as  
a DaemonSet on your cluster. It allows to automatically:

* Expose the number of GPUs on each nodes of your cluster
* Keep track of the health of your GPUs
* Run GPU enabled containers in your Kubernetes cluster.

Execute the following to install the DaemonSet on the cluster (yml installs to kube-system namespace):
```
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.9.0/nvidia-device-plugin.yml
```
Check the status with the following commands:
```
kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"

# Get a list of DaemonSets and check if nvidia device plugin is created
╰─❯ kubectl get daemonsets -n kube-system
NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
aws-node                         1         1         1       1            1           <none>                   26h
aws-node-termination-handler     1         1         1       1            1           kubernetes.io/os=linux   59m
kube-proxy                       1         1         1       1            1           <none>                   26h
nvidia-device-plugin-daemonset   1         1         1       1            1           <none>                   57s
```

### <u>Request a Certificate from AWS Certificate Manager</u> - [Additional Info](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
Execute the following command to generate a ACM Certificate that will be used with the Kubeflow  
configuration to connect the ingress to the URL we will setup. This probably was already done.   
If a certificate for the same URL exists, there is no need to do this.
```
aws acm request-certificate \
  --domain-name "*.babylon.beyond.ai" \
  --validation-method DNS \
  --idempotency-token 1234 \
  --options CertificateTransparencyLoggingPreference=DISABLED
```
Take note of and record the CertificateArn that is provided:
```
{
    "CertificateArn": "arn:aws:acm:us-west-2:562046374233:certificate/e0445d16-9f12-4ee7-a846-ac6c13619986"
}
```
### <u>Configure Auth0</u> - [Auth0](https://auth0.com/)  
You will need administrator access to Auth0 to do this section. Please contact a sysadmin  
to aid you in this process. Use the following URL
[Authentication using OIDC](https://www.kubeflow.org/docs/distributions/aws/authentication-oidc/) and follow the  
instructions. Ignore the part about Github Social connection setup.  
An Auth0 app has already been created, `Babylon-BL`. It uses an existing Enterprise connction  
that is connected to Beyond.ai's Azure Active Directory.  

Make sure to update the `Allow Callback URLs` field with your intended domain and  
path, like so `https://kubeflow.babylon.beyond.ai/oauth2/idpresponse`.

---
## Step 3 - Deploy and Configure Kubeflow - [Additional Info](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/#configure-kubeflow)
Kubeflow does not work with AWS IAM Roles for Service Accounts when the node groups are unmanaged.  
We have to rely on the traditional way to assign policies to node group roles. Please refer  
to and follow the instructions [HERE](https://www.kubeflow.org/docs/distributions/aws/deploy/install-kubeflow/#option-2-use-node-group-role).

You can execute the command to find the Worker Node roles created with:
```
╰─❯ aws iam list-roles --profile bl-babylon | jq -r ".Roles[] | select(.RoleName | startswith(\"eksctl-$AWS_CLUSTER_NAME\") and contains(\"NodeInstanceRole\")).RoleName"

eksctl-babylon-1-nodegroup-1-gpu-NodeInstanceRole-FGB7PK69GRR6
eksctl-babylon-1-nodegroup-1-gpu-NodeInstanceRole-YQU0HB0S9P6C
eksctl-babylon-1-nodegroup-ng-1-NodeInstanceRole-1MHKUDMETSLJX
eksctl-babylon-1-nodegroup-ng-2-NodeInstanceRole-1W1HZ9GOHVBYK
```
The above command assumes you created the cluster with `eksctl`, which if you followed this  
document, you did.  
Change the roles in file `kfctl_aws.yaml` to match your Worker Node roles, i.e.:
```
roles:
      - eksctl-babylon-1-nodegroup-1-gpu-NodeInstanceRole-FGB7PK69GRR6
      - eksctl-babylon-1-nodegroup-1-gpu-NodeInstanceRole-YQU0HB0S9P6C
      - eksctl-babylon-1-nodegroup-ng-1-NodeInstanceRole-1MHKUDMETSLJX
      - eksctl-babylon-1-nodegroup-ng-2-NodeInstanceRole-1W1HZ9GOHVBYK
```

The `kfctl_aws.yaml` has **already been downloaded and modified**. Certain modifications that need to be  
made if you want to make changes are the following:

* Update the `metadata.name` on line 6 with the Kubernetes cluster name, i.e. `babylon-1`.
* Update the cluster name property value for the `alb-ingress-controller` on line 364.
* Update `metadata.clusterName` on line 4 with FQDN Kubernetes cluster name
    * Execute `kubectl config current-context`.
    * Get the name of the cluster after the @ sign, i.e. `1619106470855186200@babylon-1.us-west-2.eksctl.io`.
* Find all occurenced of `certArn` and replace with the ARN of the certificate you made above.
* Update the Auth0 Client Id and Secret values: `oAuthClientId` and `oAuthClientSecret`.
* If you are using a different Auth0 tenant, then you must replace the   
  `https:/ai-beyond.auth0.com/` domain everywhere in the `kfctl_aws.yaml` file.
    * `oidcAuthorizationEndpoint`
    * `oidcIssuer`
    * `oidcTokenEndpoint`
    * `oidcUserInfoEndpoint`
* If you are using a different AWS region, you must replace the old, `us-west-2`, with the new.

### <u>Execute kfctl and apply the yaml file</u> 

From within the `babylon-1` folder execute:
```
# Set an environment variable for your AWS cluster name.  This will be picked by 
# kfctl and set value to metadata.name. alb-ingress-controller requires correct 
# value to provision application load balancers. Alb will be only created with 
# correct cluster name.
export AWS_CLUSTER_NAME=<YOUR EKS CLUSTER NAME>

kfctl apply -V -f kfctl_aws.yaml
```
The above command will go through and instantiate all the Kubeflow pieces in the cluster.  
The `babylon-1` folder will be populated with new files generated from the process.  

Wait for all the resources to become ready in the kubeflow namespace. From my experience so far,  
this takes roughly 20-30 mins to have all resources finally be *READY*. 
```
kubectl -n kubeflow get all
```
When all the resources are finally *READY*, you can execute this command to get the URL to the  
KubeFlow central dashboard:
```
kubectl get ingress -n istio-system

NAMESPACE      NAME            HOSTS   ADDRESS                                                             PORTS   AGE
istio-system   istio-ingress   *       a743484b-istiosystem-istio-2af2-xxxxxx.us-west-2.elb.amazonaws.com   80      1h
```
If you so choose, you can go into `Route53` and set a custom domain to forward to the ALB URL  
from that command.

Just as reference, if needed, you can delete the Kubeflow installation from your cluster with:
```
kfctl delete -V -f kfctl_aws.yaml
```