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
* eksctl - *(official CLI for Amazon EKS)*
    * [Install/Upgrade eksctl - OSX/Linux/Windows](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
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
To delete the cluster, you can use the following command:  
```
eksctl delete cluster -f aws-eks-cluster.yaml --profile bl-babylon
```

--------------------------
# *HERE - START FROM HERE*
--------------------------


The cluster at this point will not have any node groups. Next, we must launch a managed  
node group of Linux EC2 nodes that register with our new cluster. After the nodes join the  
cluster, we can start to deploy the Kubeflow pieces as well as any other application specific  
containers to the cluster. More detail [here](https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html).  
```
eksctl create nodegroup \
  --cluster babylon-1 \
  --region us-west-2 \
  --name ng1-m5large \
  --tags "k8s.io/cluster-autoscaler/node-template/label/project=babylon,k8s.io/cluster-autoscaler/node-template/label/creator=paloul,k8s.io/cluster-autoscaler/node-template/label/type=application" \
  --node-type m5.large \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key BL-Babylon \
  --managed \
  --node-labels "project=babylon,creator=paloul,type=application" \
  --asg-access \
  --full-ecr-access \
  --alb-ingress-access \
  --external-dns-access \
  --profile bl-babylon
```
Take note that we are creating a node group with 1 node and m5.large EC2 Instance types.  
The node group is allowed a minimum of 1 node and maximum of 4 nodes. Once completed you  
should see the following:  
```
[✔]  created 1 managed nodegroup(s) in cluster "babylon-1"
[ℹ]  checking security group configuration for all nodegroups
[ℹ]  all nodegroups have up-to-date configuration
```  
We can also create another node group designated for GPU capable nodes as Spot EC2 instances:
```
eksctl create nodegroup \
  --cluster babylon-1 \
  --region us-west-2 \
  --name ng2-p32xlarge \
  --tags "k8s.io/cluster-autoscaler/node-template/label/project=babylon,k8s.io/cluster-autoscaler/node-template/label/creator=paloul,k8s.io/cluster-autoscaler/node-template/label/type=worker,k8s.io/cluster-autoscaler/node-template/label/k8s.amazonaws.com/accelerator=nvidia-tesla-v100" \
  --node-zones "us-west-2a" \
  --node-type p3.2xlarge \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key BL-Babylon \
  --managed \
  --spot \
  --node-labels "project=babylon,creator=paloul,type=worker,k8s.amazonaws.com/accelerator=nvidia-tesla-v100" \
  --asg-access \
  --full-ecr-access \
  --alb-ingress-access \
  --external-dns-access \
  --install-nvidia-plugin \
  --profile bl-babylon
```  
The script behind `eksctl` is able to determine that GPU-enabled instance types are being  
requested and will automatically select the right AMI for the nodes in the node group.  

With nothing else running on the cluster you can check `kubectl` and see similar output:  
```
╰─❯ kubectl get nodes
NAME                                          STATUS   ROLES    AGE     VERSION
ip-192-168-25-95.us-west-2.compute.internal   Ready    <none>   3m58s   v1.19.6-eks-49a6c0

╰─❯ kubectl get pods -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
aws-node-mv9x8             1/1     Running   0          4m3s
coredns-6548845887-5rkjj   1/1     Running   0          9d
coredns-6548845887-fx6mm   1/1     Running   0          9d
kube-proxy-rh8xr           1/1     Running   0          4m3s
```
The node group starts up live EC2 machines that charge by the hour. In order to avoid being  
charged while not in use please use the following command to delete your nodegroup (modify as needed):
```
eksctl delete nodegroup --cluster babylon-1 --name ng1-m5large --profile bl-babylon
eksctl delete nodegroup --cluster babylon-1 --name ng2-p32xlarge --profile bl-babylon
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
* Find the `node-group-auto-discovery` property and add your cluster name to the end, i.e. 
`--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>`.
* Fine the `image` property and set the right image version to match your Kubernetes cluster, i.e. `image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.19.1`  

Verify that the Cluster Autoscaler was successfully launched:
```
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```
----
## Step 3 - Deploy and Configure Kubeflow - [Additional Info](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/#configure-kubeflow)
Kubeflow supports the use of AWS IAM Roles for Service Accounts to fine grain control  
AWS service access. This feature is only available for EKS controlled Kubernetes clusters.  
More information on the use of Roles for Service Accounts can be found [here](https://www.kubeflow.org/docs/aws/deploy/install-kubeflow/#option-1-use-iam-for-service-account) and [here](https://www.kubeflow.org/docs/aws/iam-for-sa/).  
Enabling it is as simple as making sure `enablePodIamPolicy:true` is defind in `kfctl_aws.yaml`. 

Execute the following either as separate commands in your terminal or the helper script  
provided in this repo, `kfctl_env-vars.sh`.  

```
# Use the following kfctl configuration file for AWS setup without authentication:
export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.2-branch/kfdef/kfctl_aws.v1.2.0.yaml"

# Set an environment variable for your AWS cluster name.
export AWS_CLUSTER_NAME=babylon-1

# Create the directory you want to store deployment, this has to be ${AWS_CLUSTER_NAME}
mkdir ${AWS_CLUSTER_NAME} && cd ${AWS_CLUSTER_NAME}

# Download your configuration files, so that you can customize the configuration before deploying Kubeflow.
wget -O kfctl_aws.yaml $CONFIG_URI
```  
As a PoC, we are not using any advanced authentication for Kubeflow. Open the `kfctl_aws.yaml`  
and change the default username and password.  
```
spec:
  auth:
  basicAuth:
    password: 12341234
    username: admin@kubeflow.org
```  
