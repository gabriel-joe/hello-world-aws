import os
import subprocess
import boto3
import docker
import json
import base64
from botocore.exceptions import ClientError


def update_infra(terraform_dir, variables_file=None):
    """
    Executes a specific Terraform module to create resources (e.g., ECR repository).

    Args:
        terraform_dir (str): The directory containing the Terraform configuration.
        module_name (str): The name of the Terraform module to execute.
        variables_file (str, optional): Path to the Terraform variables file (default: None).

    Returns:
        dict: A dictionary containing the Terraform output values.
    """

    print("** Init terraform **")
    command = ["terraform", "init"]

    # Add variables file if provided
    if variables_file:
        command.append(f"-var-file={variables_file}")

    # Execute Terraform init
    subprocess.run(command, check=True, cwd=terraform_dir)

    print("** Running terraform **")
    command = ["terraform", "apply", "-auto-approve"]

    # Execute Terraform apply for the module
    subprocess.run(command, check=True, cwd=terraform_dir)

    command = ["terraform", "output", "-json"]
    # Execute Terraform output with JSON format
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=terraform_dir)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print(f"Error getting Terraform output: {stderr.decode()}")
        return None

    # Load Terraform output from JSON string
    try:
        output_data = json.loads(stdout.decode())
    except json.JSONDecodeError as e:
        print(f"Error parsing Terraform output JSON: {e}")
        return None
    return output_data



if __name__ == "__main__":
    # Values usage
    image_name = "hello-world-aws"
    # change for another tag usage
    tag = "latest"
    terraform_dir = "./terraform/"  # Terraform project directory
    variables_file = "./terraform/terraform.tfvars"  # Optional, replace with path to Terraform variables file
    outputs_infra = update_infra(terraform_dir, variables_file)
