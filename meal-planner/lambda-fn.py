import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    try:
        print("Received event:", json.dumps(event))  # Debugging

        operation = event.get("operation", "")
        payload = event.get("payload", {})

        if operation == "create":
            table_name = payload.get("TableName", "")
            item = payload.get("Item", {})

            if not table_name or not item:
                return {"statusCode": 400, "body": json.dumps("Missing TableName or Item data.")}

            print(f"Using table: {table_name}")  # Debugging
            table = dynamodb.Table(table_name)

            # Generate unique RecipeID if not provided
            if "RecipeID" not in item:
                item["RecipeID"] = str(uuid.uuid4())

            if "Hobbies" in item:
                item["Hobbies"] = {k: v for k, v in item["Hobbies"].items()}

            if "Ingredients" in item:
                item["Ingredients"] = list(map(str, item["Ingredients"]))  # Convert elements to plain strings

            print("Inserting item:", json.dumps(item))  # Debugging
            table.put_item(Item=item)

            return {"statusCode": 200, "body": json.dumps(f"Item added successfully to {table_name}")}

        else:
            return {"statusCode": 400, "body": json.dumps("Unsupported operation. Use 'create'.")}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}
