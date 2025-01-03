## compare variables from an environment variables file (.env format) and a JSON file, identifying differences in the key-value pairs

import json
import re
import os

def parse_env_file(file_path):
    variables = {}
    with open(file_path, 'r') as file:
        for line in file:
            match = re.match(r"(\w+)\s*=\s*('?)(.+)\2", line.strip())
            if match:
                name, _, value = match.groups()
                variables[name] = value
    return variables

def parse_json_file(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON file: {e}")
        print("Attempting to parse line by line...")
        variables = {}
        for line in content.split('\n'):
            line = line.strip()
            if line:
                try:
                    parsed = json.loads(line)
                    if isinstance(parsed, dict):
                        variables.update(parsed)
                    else:
                        print(f"Skipping non-object JSON: {line}")
                except json.JSONDecodeError:
                    key_value = line.split(':', 1)
                    if len(key_value) == 2:
                        key, value = key_value
                        variables[key.strip()] = value.strip().strip('"')
                    else:
                        print(f"Skipping invalid line: {line}")
        return variables

def compare_variables(env_vars, json_vars):
    all_keys = sorted(set(env_vars.keys()) | set(json_vars.keys()))
    
    differences = 0
    for key in all_keys:
        env_value = env_vars.get(key, '<missing>')
        json_value = json_vars.get(key, '<missing>')
        
        if env_value != json_value:
            print(f"Difference for {key}:")
            print(f"  Env file: {env_value}")
            print(f"  JSON file: {json_value}")
            print()
            differences += 1
    
    print(f"Total differences found: {differences}")

def get_file_path(file_type):
    while True:
        path = input(f"Enter the path to the {file_type} file: ").strip()
        expanded_path = os.path.expanduser(path)
        if os.path.isfile(expanded_path):
            return expanded_path
        else:
            print(f"File not found. Please enter a valid file path.")

# Prompt for file locations
env_file_path = get_file_path("environment variables text")
json_file_path = get_file_path("JSON")

# Parse the files
env_variables = parse_env_file(env_file_path)
json_variables = parse_json_file(json_file_path)

# Compare and print differences
compare_variables(env_variables, json_variables)