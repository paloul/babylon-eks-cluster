## This readme goes thru the creation of the supporting RDS instances for Babylon

### Create the VPC
We will first create a VPC with the CIDR block 10.21.20.0/24 which accommodate 254 hosts in all. This is more than enough to host our RDS instance.

```
aws ec2 create-vpc --cidr-block 10.21.20.0/24 | jq '{VpcId:.Vpc.VpcId,CidrBlock:.Vpc.CidrBlock}'
# Export the RDS VPC ID for easy reference in the subsequent commands
# export RDS_VPC_ID=[VALUE]

```
## TODO: Continue this with this link 
https://dev.to/bensooraj/accessing-amazon-rds-from-aws-eks-2pc3#setup-the-mysql-database
