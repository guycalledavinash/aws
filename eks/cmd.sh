run aws configure 

# cd to usr/local/bin

# download Kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod 700 /usr/local/bin/kubectl
kubectl version

#stay in usr/local/bin

# Download eksctl

# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

#https://documentation.sisense.com/latest/linux/prepeks.htm#gsc.tab=0
## aws configure
#aws configure
#AWS_REGION=$(aws configure get region)
#AWS_REGION=us-east-1

# this takes about 15 mins
eksctl create cluster \
--name "avinash-eks-cluster" \
--version 1.32  \
--zones=us-east-1a,us-east-1b,us-east-1c \
--without-nodegroup


eksctl utils associate-iam-oidc-provider \
	--region us-east-1 \
	--cluster avinash-eks-cluster \
	--approve
aws eks describe-cluster --name avinash-eks-cluster --query cluster.identity.oidc.issuer --output text

#For Node Group In Public Subnet
# eksctl create nodegroup --cluster=avinash-eks-cluster \
                   #--region=us-east-1 \
                   #--name=avinash-eks-cluster-ng-1 \
                   #--node-type=t3.medium \
                   #--nodes=2 \
                   #--nodes-min=2 \
                   #--nodes-max=4 \
                   #--node-volume-size=20 \
                   #--ssh-access \
                   #--ssh-public-key=n.virginia \
                   #--managed \
                   #--asg-access \
                   #--external-dns-access \
                   #--full-ecr-access \
                   #--appmesh-access \
                   #--alb-ingress-access

#For Node Group In Private
eksctl create nodegroup --cluster=avinash-eks-cluster \
                   	--region=us-east-1 \
                   	--name=avinash-eks-cluster-ng-1 \
                   	--node-type=t3.medium \
                   	--nodes=2 \
                   	--nodes-min=1 \
                   	--nodes-max=2 \
                   	--node-volume-size=20 \
                   	--ssh-access \
                   	--ssh-public-key=n.virginia \
                   	--managed \
                   	--asg-access \
                   	--external-dns-access \
                   	--full-ecr-access \
                   	--appmesh-access \
                   	--alb-ingress-access                	 
