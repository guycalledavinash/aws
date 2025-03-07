## Microservices Application Deployed to EKS Cluster

In my recent POC, I containerized a 3-tier, microservice architecture application and deployed to EKS cluster using the attached manifests.

Front end is written in Python and Node

Worker in .NET

Redis for cache memory

And PostgreSQL for DB, along with persistent volume for backup

OIDC (OpenID Connect) for enabling IAM roles for service accounts

![Screenshot 2025-03-06 212002](https://github.com/user-attachments/assets/575fb39c-6649-4c59-a364-e7269d9add3b)

![Screenshot 2025-03-06 215735](https://github.com/user-attachments/assets/94d10c2e-bef3-49f4-9c3c-88af9bf3ec17)

![Screenshot 2025-03-06 215500](https://github.com/user-attachments/assets/e11581cc-6a8c-45fe-ab06-3979743cf155)

![Screenshot 2025-03-06 215633](https://github.com/user-attachments/assets/c25a22bc-e4a9-4fed-9a12-cb81a1a81552)

![Screenshot 2025-03-06 215930](https://github.com/user-attachments/assets/959e888e-0b0e-4463-aa7c-6c5ac809c5f4)

![Screenshot 2025-03-06 215640](https://github.com/user-attachments/assets/49bb268a-3a79-4312-a349-5a745632ad74)
