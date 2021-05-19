# Kubeflow PoC (for AWS)

This repo contains a poc effort for Kubeflow up on AWS EKS. Ideally, it is to help explore the capabilities of kubeflow in regards to the larger Babylon effort.

The actual kubeflow instructions are available at [Install Kubeflow on AWS](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/). Another good documentation page is [End-to-End Kubeflow on AWS](https://www.kubeflow.org/docs/distributions/aws/aws-e2e/)


### Prerequisites
--------------------------------------------
* yq - *(CLI processor for yaml files)*
    * [Github page](https://github.com/mikefarah/yq)
        * `curl --silent --location "https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64.tar.gz" | tar xz && sudo mv yq_linux_amd64 /usr/local/bin/yq`
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
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```
Open the Cluster Autoscaler deployment configuration file for editing: 
* Find the `node-group-auto-discovery` property in the autoscaler command deployment flag section  
and add your cluster name to the end, i.e. 
`--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>`.
* In the same section as the node-group-auto-discovery, add: `- --balance-similar-node-groups`
* In the same section as the node-group-auto-discovery, add: `- --skip-nodes-with-system-pods=false`
* Find the `image` property and set the right image version to match your Kubernetes cluster, i.e. `image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.18.3`. Kubernetes Version 1.18 is defined in the file  
`aws-eks-cluster-spec.yaml`. If you have changed the version there, you should change it here as well.  

Execute the following to create the cluster autoscaler.
```
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```
Verify that the Cluster Autoscaler was successfully launched:
```
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
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
  --domain-name "babylon.beyond.ai" \
  --subject-alternative-names "*.babylon.beyond.ai" \
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
document, you did use `eksctl`.  
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
# Set the profile to use for underlying commands executed by kfctl.
# This is needed because `kfctl` does not use the `--profile` option 
# when executing underlying `aws` and `eksctl` commands.
export AWS_PROFILE=bl-babylon

# Set an environment variable for your AWS cluster name.  This will be picked by 
# kfctl and set value to metadata.name. alb-ingress-controller requires correct 
# value to provision application load balancers. Alb will be only created with 
# correct cluster name.
export AWS_CLUSTER_NAME=babylon-1

kfctl apply -V -f kfctl_aws.yaml
```
The above command will go through and instantiate all the Kubeflow pieces in the cluster.  
The `babylon-1` folder will be populated with new files generated from the process.  

Wait for all the resources to become ready in the kubeflow namespace. From my experience so far,  
this takes roughly 20-30 mins to have all resources finally be *READY*. 
```
kubectl -n kubeflow get all
```
When all the resources are finally *READY*, you can proceed to the next steps.

### <u>Install the AWS LB Controller</u> [AWS LB Controller Details](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
Kubeflow installs and maintains its own version of CertManager. AWS LB Controller also relies on a  
CertManager. The CertManager installed by the steps outlined in AWS Documentation is not compatible  
with Kubeflow. This is why we install the AWS Load Balancer Controller after installing Kubeflow.  
This ensures that we have a CertManager installed by Kubeflow beforehand.  
You should already have an OIDC Provider URL if you used `eksctl` to create the cluster. Follow the steps  
here to create the Load Balance Controller.
```
# View your cluster's OIDC provider URL.
─❯ aws eks describe-cluster --name babylon-1 --query "cluster.identity.oidc.issuer" --output text
https://oidc.eks.us-west-2.amazonaws.com/id/95C5D66AFF33506402839B87BA994EFF

# List the IAM OIDC providers in your account.
─❯ aws iam list-open-id-connect-providers | grep 95C5D66AFF33506402839B87BA994EFF
"Arn": "arn:aws:iam::562046374233:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/95C5D66AFF33506402839B87BA994EFF"

# If output is returned from the previous command, then you already have a provider for your cluster.

# Create an IAM policy from the json already downloaded, lb-controller-iam_policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://lb-controller-iam_policy.json

# Create an IAM role and annotate the Kubernetes service account named 
# aws-load-balancer-controller in the kube-system namespace
# Get the policy ARN from the AWS IAM Policy Console
  eksctl create iamserviceaccount \
  --cluster=babylon-1 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve                
```
Make the following change to the already provided file, `lb-controller-v2_1_3_full.yaml`:
1. On Line 477, if you are using a different cluster name, set it here:
    * `- --cluster-name=babylon-1`
Apply the YAML Description for the Load Balancer Controller:
```
kubectl apply -f lb-controller-v2_1_3_full.yaml
```
Verify that the controller was created and functioning:
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### <u>Configure External Ingress with AWS ALB and HTTPS</u> 
We need to find some parameters to set values for the ALB Health Checks. Refer to this [Link](https://itnext.io/istio-external-aws-application-loadbalancer-and-istio-ingress-gateway-fce3bfd3202f) for more details.
```
# Find the port used for health checks by istio
kubectl -n istio-system edit svc istio-ingressgateway
```
In its *spec.ports* find the *status-port* and its *nodePort*, i.e. 30462:
```
spec:
  clusterIP: 172.20.190.253
  externalTrafficPolicy: Cluster
  ports:
  - name: status-port
    nodePort: 30462
    port: 15021
    protocol: TCP
    targetPort: 15021
```
Now find the healthcheck path used by istio for its readiness probe:
```
kubectl -n istio-system get deploy istio-ingressgateway -o yaml
```
Look for *readinessProbe* section and take note of the path, i.e. /healthz/ready:
```
readinessProbe:
    failureThreshold: 30
    httpGet:
        path: /healthz/ready
        port: 15021
        scheme: HTTP
    initialDelaySeconds: 1
    periodSeconds: 2
    successThreshold: 1
    timeoutSeconds: 1
```
Edit the **istio-ingressgateway** service with two new annotations containing the info we identified above
```
kubectl -n istio-system edit svc istio-ingressgateway

# Add these under the annotations field
alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
alb.ingress.kubernetes.io/healthcheck-port: "30462"

# And save which will update the service, use *Shift+zz* as the editor is vi
```
Next is to create the Ingress which will create the actual Application Load Balancer with SSL termination. The file is already created and in **babylon-1** folder. There are only two potential modifications that can be made. 
1. Line 13 update the Certificate ARN with the intended Certificate from AWS ACM
2. Line 19 if you are potentially using a different URL. Make sure the Certificate supports the hostname
```
╰─❯ kubectl apply -f kubeflow-babylon-alb-ingress.yaml
ingress.extensions/kubeflow-babylon-alb created
```
Check if the Ingress was property created and the Address was populated with a URL. The URL here is the  
external internet facing URL given to the Load Balancer. 

```
╰─❯ kubectl get ingress -n istio-system
NAME                   CLASS    HOSTS   ADDRESS                                                                  PORTS   AGE
kubeflow-babylon-alb   <none>   *       k8s-istiosys-kubeflow-b5c0f2d4f8-112067463.us-west-2.elb.amazonaws.com   80      149m
```
You should also visit the AWS EC2 Portal and verify the Application Load Balancer was created there.

### <u>Setup the actual custom DNS Hostname</u> 
Go into `Route53` and set a custom domain to forward to the default ALB URL shown above. You should  
create a `CNAME` entry of the new custom host to the default URL given to the ALB. 
```
# For example
kubeflow.babylon.beyond.ai	CNAME	Simple	-	
k8s-istiosys-kubeflow-b5c0f2d4f8-112067463.us-west-2.elb.amazonaws.com
```

### <u>Add Static Users to Kubeflow</u> [Details](https://www.kubeflow.org/docs/distributions/aws/deploy/install-kubeflow/#add-static-users-for-basic-authentication)
The Kubeflow 1.3 yaml does not have any users defined. Kubeflow was created without any default users or namespace. Follow the instructions outlined at the link above to add static users.  
```
# Edit the dex config with extra users.
kubectl edit configmap dex -n auth

# As an example, add new users to the file like below.
# Use this site to generate hash from password strings,
# https://passwordhashing.com/BCrypt
 staticPasswords:
    - email: user@example.com
      hash: $2y$12$4K/VkmDd1q1Orb3xAt82zu8gk7Ad6ReFR4LCP9UeYE90NLiN9Df72
      # https://github.com/dexidp/dex/pull/1601/commits
      # FIXME: Use hashFromEnv instead
      username: user
      userID: "15841185641784"
    - email: babylon@beyond.ai
      hash: $2b$10$feRbc3bM.PwhbxPMkPi1z.WqfzJ8mvCjwVYNhQyjBfYd.f7BtNsZq
      username: babylon
      userID: "15841185641882"

# After editing the config, restart Dex to pick up the changes in the ConfigMap
kubectl rollout restart deployment dex -n auth
```
Next you have to create the Profile Namespace for users to "work" in. A profile file is provided.
More information and details are [Here](https://www.kubeflow.org/docs/distributions/aws/deploy/install-kubeflow/#post-installation).
```
╰─❯ kubectl apply -f babylon-profile.yaml
profile.kubeflow.org/babylon created
```

### <u>Deleting the Kubeflow Installation</u> 
Just as reference, if needed, you can delete the Kubeflow installation from your cluster with:
```
kfctl delete -V -f kfctl_aws.yaml
```