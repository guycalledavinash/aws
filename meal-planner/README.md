### This is an event-driven architecture to provide users with personalized recipe suggestions from a predefined dataset based on their input ingredients.


![image](https://github.com/user-attachments/assets/993a81d4-7838-477f-a748-f299417e8ec4)


✅S3 Hosts the front end where users enter ingredients.

✅API Gateway – Routes requests between frontend and backend.

✅Lambda – Processes inputs, fetches recipes and interacts with the model.

✅DynamoDB – Stores user preferences, any restrictions and their meal history.
