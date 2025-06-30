# AI-Enhanced Todo Application with Radius

This sample demonstrates a Todo application that uses AI capabilities to provide feedback on tasks, leveraging Radius for deployment across different cloud providers.

## Sample Overview

This sample showcases how to deploy a containerized application that connects to different AI services using Radius. The sample includes:

- A Resource type definition for AI feedback in types.yaml
- Terraform recipes for deploying the application on Azure and AWS
- TodoList application defined in Bicep


## How to deploy the sample?

### Pre-requisites

- A kubernetes cluster (Azure AKS or AWS EKS) to host Radius control plane and the application
- [Radius CLI](https://docs.radapp.io/getting-started/install/)
-  [Azure and AWS cloud providers configured in Radius](https://docs.radapp.io/guides/operations/providers/overview/)

### 1. Create AI resource-type 

```bash
rad resource-type create feedbackAI -f types.yaml
```
### 2. Create Bicep extension 

```bash
rad bicep publish-extension -f types --target radiusResources.tgz
```

### 3. Verify the extension in `bicepconfig.json`
Open bicepconfig.json and verify the `radiusResources` extension is referencing the correct archive file. Bicep extensions in the same working directory can be the filename only. If you move the bicepconfig.json file or the extension archive, you must specify the full file path (not a relative path).

### 4. Publish Recipes

In this sample, we use Terraform configuration as Recipes to deploy Azure Open AI and AWS bedrock services. When you register a recipe with Radius, you are only creating a pointer to a Terraform configurations. Terraform configurations are stored in a git repository. In this sample we are ignoring authentication to the Git repository and container registry. If you need to setup authentication see [this for Terraform](https://docs.radapp.io/guides/recipes/terraform/howto-private-registry/).

**openAI**
Push the Terraform configuration to a Git repository. You must use the standard Terraform naming scheme. In this case, the main.tf file is in the openAI directory and requires parameters resource group and location to be passed to the recipe while registering.

**awsBedrock**
Push the Terraform configuration to a Git repository. The main.tf file is in the awsBedrock

### 5a Set up an Azure Environment and Register openAI Recipe

1. Create a resource group for the environment 

```
rad group create azure
```

Update the env.bicep file with your Azure subscription and resource group (twice). You will need to update this block:
```
providers: {
  azure: {
    // Update subscription and resource group
    scope: '/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>'
  }
}
```
And this block in the openAI recipe:
```
parameters: {
  // Update resource group name
  resource_group_name: 'nimble-dev'
  location: 'eastus'
}
```
Create the nimble-dev environment and the Jira resource in that environment.
```
rad deploy env-azure.bicep --group azure
```
If you get a `Error: no environment name or ID provided, pass in an environment name or ID`, you may need to create a dummy environment as a workaround for [this bug](https://github.com/radius-project/radius/issues/9453).

Create a workspace.
```
rad workspace create kubernetes azure \
  --context `kubectl config current-context` \
  --environment azure \
  --group azure
```

Confirm the environment was created. You should see this output.
```
$ rad environment list
RESOURCE   TYPE                            GROUP    STATE
azure      Applications.Core/environments  azure    Succeeded
```

### 5b. Setup an AWS Environment and Register awsBedrock Recipe

1. Create a resource group for the environment 

```
rad group create aws
```

Update the env.bicep file with your AWS Account and regio. You will need to update this block:
```
providers: {
  aws: {
    // Update account and region
    scope: '/account/<account-id>/regions/<region-name>'
  }
}
```

Create the  environment and the Jira resource in that environment.
```
rad deploy env-aws.bicep --group azure
```
If you get a `Error: no environment name or ID provided, pass in an environment name or ID`, you may need to create a dummy environment as a workaround for [this bug](https://github.com/radius-project/radius/issues/9453).

Create a workspace.
```
rad workspace create kubernetes aws \
  --context `kubectl config current-context` \
  --environment aws \
  --group aws
```

Confirm the environment was created. You should see this output.
```
$ rad environment list
RESOURCE   TYPE                            GROUP    STATE
aws        Applications.Core/environments  aws    Succeeded
```

### 6. Deploy the TodoList Application

Now that you have the environments set up, you can deploy the TodoList application to your Azure or AWS environment.

```
rad deploy todolist.bicep
```

## Cloud Providers & AI Services

### Azure OpenAI

The application can connect to Azure OpenAI's model for natural language processing. The Terraform recipe configures:

- An Azure Cognitive Services account with OpenAI capabilities
- LLM model deployment with configurable capacity

### AWS Bedrock

Alternatively, the application can use AWS Bedrock with Anthropic's Claude 3 Sonnet model. The Terraform recipe sets up:

- IAM user with appropriate permissions to invoke Bedrock models
- Access key management for secure API access
- Policy configuration for model invocation