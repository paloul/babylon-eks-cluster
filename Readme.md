# Kubeflow PoC (for AWS)

This repo contains a poc effort for Kubeflow up on AWS EKS. Ideally, it is to help explore the capabilities of kubeflow in regards to the larger Babylon effort.

The actual kubeflow instructions are available at [Install Kubeflow on AWS](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/).


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
eksctl create cluster -f aws-eks-cluster.yaml --profile bl-babylon
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
### Delete the EKS Cluster When Not Needed
One node group starts up a min 2 EC2 machines that charge by the hour. The other node groups  
are setup to scale down to 0 and only ramp up when pods are needed. In order to avoid being  
charged while not in use please use the following command to delete your cluster:
```
eksctl delete cluster -f aws-eks-cluster.yaml --profile bl-babylon
```  
### Kubernetes Cluster Autoscaler - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)
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
### Install Spot Instance Termination Handler for Kubernetes - [Additional Info](https://github.com/aws/aws-node-termination-handler)  
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

### Install the Nvidia Kubernetes Device Plugin - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html#gpu-ami)
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

---
## Step 3 - Deploy and Configure Kubeflow - [Additional Info](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/#configure-kubeflow)
Kubeflow supports the use of AWS IAM Roles for Service Accounts to fine grain control  
AWS service access. This feature is only available for EKS controlled Kubernetes clusters.  
More information on the use of Roles for Service Accounts can be found [here](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/#option-1-use-iam-for-service-account) and [here](https://www.kubeflow.org/docs/aws/iam-for-sa/).  
Enabling it is as simple as making sure `enablePodIamPolicy:true` is defind in `kfctl_aws.yaml`.  

The `kfctl_aws.yaml` has already been downloaded and user/password modified. It will be  
imporant to update the username/password to your choosing. The yaml is configured to only  
support Basic Authentication. Future work can be to move towards an oAuth authentication  
using our Beyond.AI AAD.  

From within the `babylon-1` folder execute:
```
kfctl apply -V -f kfctl_aws.yaml
```

