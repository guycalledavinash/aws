### This is an event-driven architecture to provide users with personalized recipe suggestions from a predefined dataset based on their input ingredients.

![image](https://github.com/user-attachments/assets/993a81d4-7838-477f-a748-f299417e8ec4)

✅S3 Hosts the front end where users enter ingredients.

✅API Gateway – Routes requests between frontend and backend.

✅Lambda – Processes inputs, fetches recipes and interacts with the model.

✅DynamoDB – Stores user preferences, any restrictions and their meal history.

![11](https://github.com/user-attachments/assets/cc25a291-92cf-44e6-861d-9bcc7ff87ff6)

## Lambda configuration and request contract

Configure the Lambda environment variable `MEAL_PLANNER_TABLE` with the name of the recipe table. The table name is server-side configuration; callers must not send `TableName` or select a table.

The Lambda execution role should have only the DynamoDB actions it needs on that table: `dynamodb:PutItem` and `dynamodb:GetItem`, with the resource restricted to the configured table ARN (and its indexes only if the implementation later needs them). It does not require broad table or account access.

### Requests

The handler accepts an API Gateway-compatible JSON event:

Create a recipe:

```json
{
  "operation": "create",
  "payload": {
    "Item": {
      "RecipeID": "recipe-123",
      "Name": "Grilled Cheese",
      "Ingredients": ["bread", "cheese", "butter"],
      "Hobbies": {"Act1": "Cooking"}
    }
  }
}
```

Omit `RecipeID` to have the Lambda generate a UUID.

Get a recipe by its DynamoDB key:

```json
{
  "operation": "get",
  "payload": {
    "Key": {"RecipeID": "recipe-123"}
  }
}
```

A successful create returns HTTP-style `statusCode: 200` and a JSON body such as `{"message":"Recipe created.","RecipeID":"recipe-123"}`. A successful get returns the recipe object. Invalid requests return `400`; a missing recipe returns `404`; missing server configuration or an unexpected DynamoDB failure returns a generic `500`. Every response has a `statusCode` and JSON-encoded `body`.

### Local tests and deployment security

Run the unit tests from the repository root without AWS credentials or network access:

```bash
python -m unittest discover -s meal-planner -p "test_*.py" -v
python -m py_compile meal-planner/lambda-fn.py meal-planner/test_lambda_fn.py
```

In a real deployment, configure API Gateway authorization (for example, an appropriate IAM authorizer or user identity provider) and request validation/schema enforcement. The Lambda validates its own input as defense in depth; this does not replace API authorization or prevent abuse of an unauthenticated endpoint.
