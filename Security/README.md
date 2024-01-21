Hi, let's see how to allow/disable authorised requests into a VPC using NACL and SG

1. Create a VPC

![Create VPC](https://github.com/guycalledavinash/aws/assets/90386560/9f428ff8-119d-4a64-bc16-732fd8a0f69d)

2. During configuration, opt for 'VPC and more' to make sure the there's both public and private subnets

![Configuration](https://github.com/guycalledavinash/aws/assets/90386560/e5e9e2bd-c95d-4ace-b239-007de3594913)

3. For the rest, proceed with default settings.

4. It's time to create an EC2 now. Go with ubuntu for convinience. Everything is default, except the network settings. Edit them > custom VPC > select the one we created. However, AWS creates the security group by default.

![VPC Settings](https://github.com/guycalledavinash/aws/assets/90386560/3677d1c8-3c2a-4903-8a85-14a50eedee90)

5. To showcase the VPC let's run a python application and run it in port 8000. [Check this out](https://github.com/guycalledavinash/aws/blob/main/Security/vpc-nacl-sg)
