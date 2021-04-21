# Use the following kfctl configuration file for AWS setup without authentication:
export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.2-branch/kfdef/kfctl_aws.v1.2.0.yaml"

# Set an environment variable for your AWS cluster name.
export AWS_CLUSTER_NAME=babylon-1

# Create the directory you want to store deployment, this has to be ${AWS_CLUSTER_NAME}
mkdir ${AWS_CLUSTER_NAME} && cd ${AWS_CLUSTER_NAME}

# Download your configuration files, so that you can customize the configuration before deploying Kubeflow.
wget -O kfctl_aws.yaml $CONFIG_URI
