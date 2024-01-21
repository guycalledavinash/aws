Hi, let's see how to allow/block traffic into a VPC using NACL and SG.

1. Create a VPC.

![Create VPC](https://github.com/guycalledavinash/aws/assets/90386560/9f428ff8-119d-4a64-bc16-732fd8a0f69d)

2. During configuration, opt for 'VPC and more' to make sure the there's both public and private subnets.

![Configuration](https://github.com/guycalledavinash/aws/assets/90386560/e5e9e2bd-c95d-4ace-b239-007de3594913)

3. For the rest, proceed with default settings.

4. It's time to create an EC2 now. Go with ubuntu for convinience. Everything is default, except the network settings. Edit them > custom VPC > select the one we created. However, AWS creates the security group by default.

![VPC Settings](https://github.com/guycalledavinash/aws/assets/90386560/3677d1c8-3c2a-4903-8a85-14a50eedee90)

5. To showcase the VPC let's run a simple python application and run it on port 8000. [Check this out](https://github.com/guycalledavinash/aws/blob/main/Security/vpc-nacl-sg)

6. Now let's try accessing this port i.e, https:publicIP:8000, as expected the security group will block the incoming request by default. Check this screenshot.

![site](https://github.com/guycalledavinash/aws/assets/90386560/a1a34b5c-1248-46fd-83b8-4af695082fa0)

7. This is because AWS wants to allow default traffic into the system, i.e, port 22 - SSH traffic

![nw](https://github.com/guycalledavinash/aws/assets/90386560/bc3527ca-970c-45e1-8ea3-9df7beeabdc7)

8. Now let's checkout NACL configuration. Least number is given priority, followed by * at the end. So as per this, all traffic is allowed to enter the subnet.

![nw](https://github.com/guycalledavinash/aws/assets/90386560/780d873a-2b64-4c9c-87a3-c6f29e42bd1f)

9. Step 8 confirmed that security layer is stopping the incoming request at the subnet level. Let's allow it.

Edit inbound rules > add a rule > allow port 8000

![port8000](https://github.com/guycalledavinash/aws/assets/90386560/bf0c2597-67fe-4183-8be2-3acc15f62a2c)

10. Yay we are through!

![job](https://github.com/guycalledavinash/aws/assets/90386560/f934aab1-6aa6-4a51-af3f-4226cafe6060)

We can block/unblock traffic from NACL too if there are limitations at SG.

Thanks
