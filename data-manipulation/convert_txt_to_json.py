#parse .env file with vars in key=value format and convert to json.

import re
import json
import os

def parse_env_file(file_path):
    variables = []
    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r"(\w+)\s*=\s*('?)(.+)\2", line.strip())
            if match:
                name, _, value = match.groups()
                variables.append({
                    "name": name,
                    "value": value
                })
    return variables

def write_json_file(variables, output_file):
    with open(output_file, 'w') as file:
        json.dump(variables, file, indent=4)

def get_file_path(prompt):
    while True:
        path = input(prompt).strip()
        expanded_path = os.path.expanduser(path)
        if os.path.isfile(expanded_path):
            return expanded_path
        else:
            print(f"File not found. Please enter a valid file path.")

# Prompt for input file location
input_file_path = get_file_path("Enter the path to the input text file: ")

# Prompt for output file location
output_file_path = input("Enter the path for the output JSON file: ").strip()

# Parse the input file
variables = parse_env_file(input_file_path)

# Write the JSON file
write_json_file(variables, output_file_path)

print(f"Conversion complete. JSON file written to {output_file_path}")
