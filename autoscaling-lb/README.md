This project is a recommended approach and demonstrates a production environment where I create a VPC, deploy the servers in two availability Zones using an Auto Scaling group and an Application Load Balancer. To secure the IP addresses, Bashtion host/Jump server comes to rescue. For additional security, the servers are in private subnets, receive requests through the load balancer and can connect to the internet using a NAT gateway. Check the below image for reference. [Source: AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-example-private-subnets-nat.html)

![Blueprint](https://github.com/guycalledavinash/aws/assets/90386560/6acc1650-d23c-4e4f-8ae3-7282953ca7e0)

In production, we need more than one availaility zone, just if one data center goes down.

Terminology:

NAT Gateway: For a server in private subnet, reaching out to internet is necessary. This makes it vulnerable as it exposes its IP address. To prevent this exposure, NAT gateway is used where the IP address of EC2 is masked with the public IP of router.

Auto Scaling: If the number of servers set up initially are not enough to handle the incoming traffic, the Auto Scaling group kicks in, decides to scale up the servers.

Bashtion Host/Jump Server: EC2 instances in private servers doesn't have public IP address. Hence, they can't be accessed directly. So, we create a jump server in the public subnet, connect to that EC2 instance.

Hands-on:

1. Create a VPC with all default settings but (i) choose 1 NAT gateway per AZ (ii) No S3

2. Create an Auto Scaling group through EC2.

![ec2](https://github.com/guycalledavinash/aws/assets/90386560/5b0348b2-7b30-4030-a52e-bf71d7320653)

3. Create a new template if you haven't before.

![newtemplate](https://github.com/guycalledavinash/aws/assets/90386560/2e1873f1-0087-4e92-870f-65a2a97d77e5)

4. Configure the security settings. Allow default port and a custom port, in my case 8000

![security](https://github.com/guycalledavinash/aws/assets/90386560/45316229-7edc-47bc-bb0e-afb820b2b1bd)
