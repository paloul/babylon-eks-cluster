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
* kustomize - *(Customize kubernetes YML configurations)*
    * You will need 4.0.5 for use with ArgoFlow for AWS
    * `curl --silent --location "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.0.5/kustomize_v4.0.5_linux_amd64.tar.gz" | tar xz -C /tmp`
    * `sudo mv /tmp/kustomize /usr/local/bin`
    * `kustomize version`
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
eksctl create cluster -f aws-eks-cluster-spec-2.yaml --profile bl-babylon
```
This command will take several minutes as `eksctl` creates the entire stack with  
supporting services inside AWS, i.e. VPC, Subnets, Security Groups, Route Tables,  
in addition to the cluster itself. Once completed you should see the following:
```
[✓]  EKS cluster "babylon-2" in "us-west-2" region is ready
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
eksctl delete cluster -f aws-eks-cluster-spec-2.yaml --profile bl-babylon
```

## Step 3 - Create the policies and roles
### <u>Kubernetes Cluster Autoscaler</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)
We need to create the appropriate policy and role for the Cluster Autoscaler.

Create the Policy and Role for the Cluster Autoscaler to work properly:
```
# The policy file is already included as part of this repo
aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://cluster-autoscaler-policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with the policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl. 
```
# Replace the attach-policy-arn field with the arn of the policy created above. 
# Put your cluster name in the cluster field.
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve
```
### <u>External-DNS</u> - [Additional Info](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md)
External-DNS is a supporting feature controller for Kubernetes that automatically assigns DNS A records  
for load balancers when a service/ingress is defined. The correct permissions need to be assigned to the  
`kube-system` namespace'd pods in order for this to function.

You will first have to create the Policy and Role for the external-dns system to work properly.  
**Important: Update hosted zone in the external-dns-policy.json to match the domain you want the policy to grant access to.**
```
# The policy file is already included as part of this repo
aws iam create-policy \
    --policy-name AmazonEKSClusterExternalDnsPolicy \
    --policy-document file://external-dns-policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with the policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl. 
```
# Replace the attach-policy-arn field with the arn of the policy created above. 
# Put your cluster name in the cluster field.
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AmazonEKSClusterExternalDnsPolicy \
  --override-existing-serviceaccounts \
  --approve
```
### <u>AWS Load Balancer Controller</u> - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
The AWS Load Balancer Controller is in charge of creating the load balancer when ingresses are defined  
in Kubernetes yaml files for services. It needs policies that allows it to schedule a NLB in specific subnets. 
```
# Create an IAM policy from the json already downloaded, lb-controller-iam_policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://lb-controller-v2_2_0-iam_policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl.
```
# Create an IAM role and annotate the Kubernetes service account named 
# aws-load-balancer-controller in the kube-system namespace
# Get the policy ARN from the AWS IAM Policy Console
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve                
```
### <u>External Secrets</u> - [Additional Info](https://github.com/external-secrets/kubernetes-external-secrets) 
Kubernetes External Secrets allows you to use external secret management systems, like AWS Secrets Manager or HashiCorp Vault, to securely add secrets in Kubernetes.  
Create the policy and the role to access the Secret stoe in AWS Secret Manager.
```
# Create an IAM policy from the json already downloaded, external-secrets-iam-policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSExternalSecretsBabylon2IAMPolicy \
    --policy-document file://external-secrets-iam-policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl.
```
# Create an IAM role and annotate the Kubernetes service account named 
# external-secrets in the kube-system namespace
# Get the policy ARN from the AWS IAM Policy Console
# Update the cluster name if different
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kube-system \
  --name=external-secrets \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSExternalSecretsBabylon2IAMPolicy \
  --override-existing-serviceaccounts \
  --approve                
```
### <u>Cert Manager</u> - [Additional Info](https://cert-manager.io/docs/)
`cert-manager` is a native Kubernetes certificate management controller. It can help with issuing  
certificates from a variety of sources, in our case, AWS' ACM. `cert-manager` needs to be able to add  
records to Route53 in order to solve the DNS01 challenge. To enable this, create a IAM policy.
```
# Create an IAM policy from the json already downloaded, cert-manager-iam_policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSCertManagerIAMPolicy \
    --policy-document file://cert-manager-iam_policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl.
```
# Create an IAM role and annotate the Kubernetes service account named 
# cert-manager in the cert-manager namespace.
# Update the cluster value
# Update the attach-policy-arn value with the arn of the policy created above
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=cert-manager \
  --name=cert-manager \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSCertManagerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve                
```
### <u>AWS FSX Lustre CSI Driver</u> - [Additional Info](https://github.com/kubernetes-sigs/aws-fsx-csi-driver)
Amazon FSx for Lustre provides a high-performance file system optimized for fast processing for machine learning and  
high performance computing (HPC) workloads. AWS FSx for Lustre CSI Driver can help Kubernetes users easily leverage this service.  

Lustre is another file system that supports ReadWriteMany. One difference between Amazon EFS and Lustre is that Lustre can be  
used to cache training data with direct connectivity to Amazon S3 as the backing store. With this configuration, you don’t need  
to transfer data to the file system before using the volume.  

The Amazon FSx for Lustre Container Storage Interface (CSI) Driver implements CSI specification for container orchestrators (CO)  
to manage lifecycle of Amazon FSx for Lustre filesystems.
```
# Create an IAM policy from the json already downloaded, aws-fsx-csi-driver-policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSFsxCsiDriverIAMPolicy \
    --policy-document file://aws-fsx-csi-driver-policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl.
```
# Create an IAM role and annotate the Kubernetes service account named 
# fsx-csi-controller-sa in the kubeflow namespace.
# Update the cluster value
# Update the attach-policy-arn value with the arn of the policy created above
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kubeflow \
  --name=fsx-csi-controller-sa \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSFsxCsiDriverIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
```

### <u>AWS EFS CSI Driver</u> - [Additional Info](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
Amazon EFS is managed NFS in AWS. Amazon EFS supports ReadWriteMany access mode, which means the volume can be mounted as  
read-write by many nodes. It is very useful for creating a shared filesystem that can be mounted into pods such as Jupyter.  
For example, one group can share datasets or models across an entire team. By default, the Amazon EFS CSI driver is not  
enabled and you need to follow steps to install it.  

The Amazon EFS Container Storage Interface (CSI) Driver implements CSI specification for container orchestrators (CO)  
to manage lifecycle of Amazon EFS filesystems.
```
# Create an IAM policy from the json already downloaded, aws-efs-csi-driver-policy.json
# This mightve already been done, you will see an error if the Policy already exists, ignore.
aws iam create-policy \
    --policy-name AWSEFSCsiDriverIAMPolicy \
    --policy-document file://aws-efs-csi-driver-policy.json
# Note the ARN returned in the output for use in a later step.
```
You can now make a new role with policy attached. You can create an IAM role and attach an IAM policy  
to it using eksctl.
```
# Create an IAM role and annotate the Kubernetes service account named 
# efs-csi-controller-sa in the kube-system namespace.
# Update the cluster value
# Update the attach-policy-arn value with the arn of the policy created above
eksctl create iamserviceaccount \
  --cluster=babylon-2 \
  --namespace=kube-system \
  --name=efs-csi-controller-sa \
  --attach-policy-arn=arn:aws:iam::562046374233:policy/AWSEFSCsiDriverIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
```