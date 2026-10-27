"""API Gateway-compatible Lambda handler for meal planner recipes."""

import json
import logging
import os
import uuid
from decimal import Decimal

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


class RequestValidationError(ValueError):
    """Raised when an incoming event does not match the handler contract."""


def get_dynamodb_resource():
    """Create the production Boto3 resource lazily, avoiding AWS setup on import."""
    import boto3

    return boto3.resource("dynamodb")


def _response(status_code, body):
    return {"statusCode": status_code, "body": json.dumps(body, default=_json_default)}


def _json_default(value):
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def _request_id(context):
    return getattr(context, "aws_request_id", "unknown")


def _validate_event(event):
    if not isinstance(event, dict):
        raise RequestValidationError("Event must be a JSON object.")

    operation = event.get("operation")
    if operation not in {"create", "get"}:
        raise RequestValidationError("Unsupported operation. Use 'create' or 'get'.")

    payload = event.get("payload")
    if not isinstance(payload, dict):
        raise RequestValidationError("Payload must be a JSON object.")

    if operation == "create":
        item = payload.get("Item")
        if not isinstance(item, dict) or not item:
            raise RequestValidationError("Item must be a non-empty JSON object.")
        if any(not isinstance(key, str) or not key.strip() for key in item):
            raise RequestValidationError("Item field names must be non-empty strings.")
        if not any(value is not None and value != "" for value in item.values()):
            raise RequestValidationError("Item must contain at least one non-empty field value.")
        if "Ingredients" in item:
            ingredients = item["Ingredients"]
            if not isinstance(ingredients, list):
                raise RequestValidationError("Ingredients must be a list.")
            if any(isinstance(value, (list, dict)) or value is None for value in ingredients):
                raise RequestValidationError("Ingredients must contain scalar values.")
        if "Hobbies" in item:
            hobbies = item["Hobbies"]
            if not isinstance(hobbies, dict):
                raise RequestValidationError("Hobbies must be an object.")
            if any(not isinstance(key, str) or not key.strip() for key in hobbies):
                raise RequestValidationError("Hobbies field names must be non-empty strings.")
        if "RecipeID" in item and (not isinstance(item["RecipeID"], str) or not item["RecipeID"].strip()):
            raise RequestValidationError("RecipeID must be a non-empty string.")
        return operation, item

    key = payload.get("Key")
    if not isinstance(key, dict) or not key:
        raise RequestValidationError("Key must be a non-empty JSON object.")
    for name, value in key.items():
        if not isinstance(name, str) or not name.strip():
            raise RequestValidationError("Key field names must be non-empty strings.")
        if isinstance(value, bool) or not isinstance(value, (str, int, float, Decimal)) or value == "":
            raise RequestValidationError("Key values must be non-empty strings or numbers.")
        if isinstance(value, float) and (value != value or value in (float("inf"), float("-inf"))):
            raise RequestValidationError("Key numeric values must be finite.")
    return operation, key


def lambda_handler(event, context, dynamodb_resource=None):
    """Handle create/get requests; tests may inject a mocked DynamoDB resource."""
    request_id = _request_id(context)
    operation = event.get("operation", "unknown") if isinstance(event, dict) else "unknown"

    try:
        operation, value = _validate_event(event)
    except RequestValidationError as exc:
        logger.info(
            "Request rejected operation=%s request_id=%s category=validation",
            operation,
            request_id,
        )
        return _response(400, {"message": str(exc)})

    table_name = os.environ.get("MEAL_PLANNER_TABLE", "").strip()
    if not table_name:
        logger.error(
            "Request failed operation=%s request_id=%s category=configuration",
            operation,
            request_id,
        )
        return _response(500, {"message": "Server configuration error."})

    try:
        resource = dynamodb_resource if dynamodb_resource is not None else get_dynamodb_resource()
        table = resource.Table(table_name)

        if operation == "create":
            item = dict(value)
            if "Ingredients" in item:
                # Preserve the original behavior for scalar ingredient values.
                item["Ingredients"] = [str(ingredient) for ingredient in item["Ingredients"]]
            if "RecipeID" not in item:
                item["RecipeID"] = str(uuid.uuid4())
            table.put_item(Item=item)
            return _response(200, {"message": "Recipe created.", "RecipeID": item["RecipeID"]})

        result = table.get_item(Key=value)
        item = result.get("Item")
        if item is None:
            return _response(404, {"message": "Recipe not found."})
        return _response(200, item)

    except Exception as exc:
        # Keep diagnostic details in category/type only; do not expose payloads or exception text.
        logger.error(
            "Request failed operation=%s request_id=%s category=dynamodb error_type=%s",
            operation,
            request_id,
            type(exc).__name__,
        )
        return _response(500, {"message": "Internal server error."})
