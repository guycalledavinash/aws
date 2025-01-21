***Let's see how to give access to a user to a specific resource like s3 bucket***

Create an S3 bucket and spin an EC2 instance, then follow below steps.

**1. Create a custom role with ec2 service, while adding an inline policy to the same role.**

 ![image](https://github.com/user-attachments/assets/b8c42650-02ad-46f7-a5ef-4a9592d4bb1e)

**2. Modify the inline policy by adding the S3 bucket's ARN using ![policy generator](https://awspolicygen.s3.amazonaws.com/policygen.html)**

![image](https://github.com/user-attachments/assets/53a3ee92-3c6e-49a8-85d3-2e9ecce05080)

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AllowAllActionsOnBucketObjects",
			"Effect": "Allow",
			"Action": "s3:*",
			"Resource": "arn:aws:s3:::bucketavi294/*"
		},
		{
			"Sid": "AllowBucketLevelActions",
			"Effect": "Allow",
			"Action": [
				"s3:ListBucket",
				"s3:GetBucketLocation"
			],
			"Resource": "arn:aws:s3:::bucketavi294"
		},
		{
			"Sid": "AllowListAllBuckets",
			"Effect": "Allow",
			"Action": "s3:ListAllMyBuckets",
			"Resource": "*"
		}
	]
}
```
**3. Attach the role to an EC2 instance**

To validate, login to the instance, make sure you have access to the bucket

```
aws s3 ls
# Try pushing a local file to the bucket to test the access
aws s3 cp [file] s3://[buket]/[file name as you wish]
```

Voila!
