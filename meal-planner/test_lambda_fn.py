import importlib.util
import json
import logging
import os
import unittest
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch
from uuid import UUID


MODULE_PATH = Path(__file__).with_name("lambda-fn.py")
SPEC = importlib.util.spec_from_file_location("meal_planner_lambda_fn", MODULE_PATH)
lambda_fn = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(lambda_fn)


class LambdaHandlerTests(unittest.TestCase):
    def setUp(self):
        self.table = Mock()
        self.resource = Mock()
        self.resource.Table.return_value = self.table
        self.context = SimpleNamespace(aws_request_id="request-test-123")
        self.environment = patch.dict(os.environ, {"MEAL_PLANNER_TABLE": "test-meal-planner"})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def invoke(self, event, **kwargs):
        return lambda_fn.lambda_handler(event, self.context, dynamodb_resource=self.resource, **kwargs)

    def body(self, response):
        return json.loads(response["body"])

    def test_create_with_supplied_recipe_id(self):
        event = {
            "operation": "create",
            "payload": {"Item": {"RecipeID": "recipe-1", "Name": "Toast", "Ingredients": ["bread", 2]}},
        }
        response = self.invoke(event)

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(self.body(response), {"message": "Recipe created.", "RecipeID": "recipe-1"})
        self.table.put_item.assert_called_once_with(
            Item={"RecipeID": "recipe-1", "Name": "Toast", "Ingredients": ["bread", "2"]}
        )
        self.resource.Table.assert_called_once_with("test-meal-planner")

    def test_create_generates_uuid(self):
        event = {"operation": "create", "payload": {"Item": {"Name": "Soup"}}}
        response = self.invoke(event)

        self.assertEqual(response["statusCode"], 200)
        recipe_id = self.body(response)["RecipeID"]
        UUID(recipe_id)
        self.table.put_item.assert_called_once_with(Item={"Name": "Soup", "RecipeID": recipe_id})

    def test_get_existing_recipe(self):
        recipe = {"RecipeID": "recipe-1", "Name": "Toast"}
        self.table.get_item.return_value = {"Item": recipe}

        response = self.invoke({"operation": "get", "payload": {"Key": {"RecipeID": "recipe-1"}}})

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(self.body(response), recipe)
        self.table.get_item.assert_called_once_with(Key={"RecipeID": "recipe-1"})

    def test_get_missing_recipe(self):
        self.table.get_item.return_value = {}
        response = self.invoke({"operation": "get", "payload": {"Key": {"RecipeID": "unknown"}}})

        self.assertEqual(response["statusCode"], 404)
        self.assertEqual(self.body(response), {"message": "Recipe not found."})

    def test_invalid_operation_and_malformed_events(self):
        invalid_events = [
            None,
            [],
            {},
            {"operation": "delete", "payload": {}},
            {"operation": [], "payload": {}},
            {"operation": "create"},
            {"operation": "get", "payload": []},
        ]
        for event in invalid_events:
            with self.subTest(event=event):
                response = self.invoke(event)
                self.assertEqual(response["statusCode"], 400)
        self.resource.Table.assert_not_called()

    def test_invalid_create_item_values(self):
        invalid_items = [None, [], {}, {"Name": ""}, {"Ingredients": "bread"}, {"Hobbies": []},
                         {"RecipeID": ""}, {"Ingredients": [None]}, {"Ingredients": [{"bad": "shape"}]}]
        for item in invalid_items:
            with self.subTest(item=item):
                response = self.invoke({"operation": "create", "payload": {"Item": item}})
                self.assertEqual(response["statusCode"], 400)
        self.resource.Table.assert_not_called()

    def test_invalid_get_key_values(self):
        invalid_keys = [None, [], {}, {"RecipeID": ""}, {"RecipeID": None}, {"RecipeID": True}]
        for key in invalid_keys:
            with self.subTest(key=key):
                response = self.invoke({"operation": "get", "payload": {"Key": key}})
                self.assertEqual(response["statusCode"], 400)
        self.resource.Table.assert_not_called()

    def test_missing_table_configuration(self):
        with patch.dict(os.environ, {}, clear=True):
            response = self.invoke({"operation": "get", "payload": {"Key": {"RecipeID": "r1"}}})
        self.assertEqual(response["statusCode"], 500)
        self.assertEqual(self.body(response), {"message": "Server configuration error."})
        self.resource.Table.assert_not_called()

    def test_dynamodb_exception_is_generic_and_logged_safely(self):
        self.table.put_item.side_effect = RuntimeError("SECRET-RECIPE-CONTENT")
        event = {
            "operation": "create",
            "payload": {"Item": {"Name": "PRIVATE-RECIPE", "RecipeID": "private-id"}},
        }

        with self.assertLogs(lambda_fn.logger, level=logging.ERROR) as captured:
            response = self.invoke(event)

        self.assertEqual(response["statusCode"], 500)
        self.assertNotIn("SECRET-RECIPE-CONTENT", response["body"])
        self.assertNotIn("PRIVATE-RECIPE", response["body"])
        self.assertNotIn("SECRET-RECIPE-CONTENT", "\n".join(captured.output))
        self.assertNotIn("PRIVATE-RECIPE", "\n".join(captured.output))
        self.assertIn("operation=create", captured.output[0])
        self.assertIn("request_id=request-test-123", captured.output[0])

    def test_validation_does_not_call_dynamodb(self):
        response = self.invoke({"operation": "create", "payload": {"Item": {"Ingredients": "not-list"}}})
        self.assertEqual(response["statusCode"], 400)
        self.resource.Table.assert_not_called()

    def test_read_decimal_item_json(self):
        self.table.get_item.return_value = {"Item": {"RecipeID": "r1", "Rating": Decimal("4.5")}}
        response = self.invoke({"operation": "get", "payload": {"Key": {"RecipeID": "r1"}}})
        self.assertEqual(self.body(response)["Rating"], 4.5)


if __name__ == "__main__":
    unittest.main()
