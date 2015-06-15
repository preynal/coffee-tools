coffee_tools = require "../index.js"

cases = [
    "./test"
]

cases.map (test_case) ->
    test_module = require test_case
    test_module coffee_tools
