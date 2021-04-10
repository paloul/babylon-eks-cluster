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
2021-04-09 16:34:00 [▶]  role ARN for the current session is "arn:aws:sts::562046374233:assumed-role/BabylonOrgAccountAccessRole/1618011239640991900"
2021-04-09 16:34:00 [ℹ]  eksctl version 0.44.0
2021-04-09 16:34:00 [ℹ]  using region us-west-2
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
 

## Step 2 - Create EKS Cluster - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
Execute the following `eksctl` command to create a cluster under the AWS Babylon account.
```
eksctl create cluster \
 --name babylon-1 \
 --version 1.19 \
 --with-oidc \
 --without-nodegroup \
 --profile bl-babylon
 ```
 This command will take several minutes as `eksctl` creates the entire stack with  
 supporting services inside AWS, i.e. VPC, Subnets, Security Groups, Route Tables,  
 in addition to the cluster itself. Once completed you should see the following:
 ```
 ```
