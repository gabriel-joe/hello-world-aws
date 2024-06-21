import os
import subprocess
import boto3
import docker
import json
import base64
from botocore.exceptions import ClientError


def update_infra(terraform_dir, module_name, variables_file=None):
    """
    Executes a specific Terraform module to create resources (e.g., ECR repository).

    Args:
        terraform_dir (str): The directory containing the Terraform configuration.
        module_name (str): The name of the Terraform module to execute.
        variables_file (str, optional): Path to the Terraform variables file (default: None).

    Returns:
        dict: A dictionary containing the Terraform output values.
    """

    command = ["terraform", "init"]

    # Add variables file if provided
    if variables_file:
        command.append(f"-var-file={variables_file}")

    # Execute Terraform init
    subprocess.run(command, check=True, cwd=terraform_dir)

    command = ["terraform", "apply", "-auto-approve", f"-target={module_name}"]

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

def get_ecr_credentials(region_name="us-east-1"):  # Set your default region here
    """
    Retrieves temporary credentials for the current AWS session using boto3,
    suitable for authenticating with AWS ECR.

    Args:
        region_name (str, optional): The AWS region where the ECR repository resides (default: "us-east-1").
    Returns:
        dict: A dictionary containing the retrieved credentials (access key, secret key, session token).
    """

    try:
        # Use the session object to get credentials for the current session
        session = boto3.Session(region_name=region_name)
        credentials = session.get_credentials().get_frozen_credentials()

        return {
            "access_key": credentials.access_key,
            "secret_key": credentials.secret_key,
            "session_token": credentials.token,
        }
    except ClientError as e:
        print(f"Error getting temporary credentials: {e}")
        return None

def build_image(image_name, tag):
    """
    Builds a Docker image using the provided Dockerfile and handles potential errors.

    Args:
        image_name (str): The name of the image to build (usually from the Dockerfile).
        tag (str): The tag for the image (e.g., "latest").

    Returns:
        Bool: The result for the build execution
    """

    print("** Building the Docker image... **")

    # Build the image
    try:
        build_log = DOCKER_CLIENT.images.build(path="../", tag=f"{image_name}:{tag}", rm=True)
        print("Build complete!")
        return True
    except docker.errors.BuildError as e:
        print(f"Error building image: {e}")
        return False   

def push_image(image_name, tag, ecr_repo_uri):
    """
    Pushes the docker image to the specified ECR repository, and handles potential errors.

    Args:
        image_name (str): The name of the image to build (usually from the Dockerfile).
        tag (str): The tag for the image (e.g., "latest").
        ecr_repo_uri (str): The URI of the ECR repository where the image will be pushed.

    Returns:
        None
    """

    print("** Setting up Docker and ECR client... **")

    registryId = ecr_repo_uri.split('.')[0]
    # Get ECR login credentials
    try:
        ecr_client = boto3.client('ecr')
        login_response = ecr_client.get_authorization_token(registryIds=[registryId])
        auth_data = login_response['authorizationData'][0]
        registry = auth_data['proxyEndpoint']
        username = base64.b64decode(auth_data['authorizationToken']).decode().split(':')[0]
        password = base64.b64decode(auth_data['authorizationToken']).decode().split(':')[1]
    except ClientError as e:
        print(f"Error getting ECR login credentials: {e}")
        return

    print("** Logging in to ECR and tagging the image... **")

    # Tag the image for ECR
    full_image_name = f"{ecr_repo_uri.split('/')[0]}/{image_name}:{tag}"
    try:
        command = ["docker", "tag", f"{image_name}:{tag}", full_image_name]
        subprocess.run(command, check=True, cwd="./")
        print("Image tagged successfully!")
    except docker.errors.APIError as e:
        print(f"Error tagging image: {e}")
        return

    print("** Pushing the image to ECR... **")

    # Push the image to ECR
    try:
        DOCKER_CLIENT.login(username=username, password=password, registry=registry)
        push_log = DOCKER_CLIENT.images.push(full_image_name)
        print(push_log)
        print("Image pushed successfully!")
    except docker.errors.APIError as e:
        print(f"Error pushing image to ECR: {e}")
        return


if __name__ == "__main__":
    # Get Docker client
    DOCKER_CLIENT = docker.from_env()
    # Values usage
    image_name = "hello-world-aws"
    # change for another tag usage
    tag = "latest"
    terraform_dir = "./terraform/"  # Terraform project directory
    module_name = "aws_ecr_repository.ecr_image_repository"  # Replace with the name of your ECR Terraform module
    variables_file = "./terraform/terraform.tfvars"  # Optional, replace with path to Terraform variables file
    outputs_infra = update_infra(terraform_dir, module_name, variables_file)
    credentials = get_ecr_credentials()
    if not credentials:
        exit(1)
    result = build_image(image_name, tag)
    if result:
        push_image(image_name, tag, outputs_infra.get('ecr_image_repository').get('value'))
