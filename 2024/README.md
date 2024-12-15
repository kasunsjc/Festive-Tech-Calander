# Deploying Bicep Templates

Follow these steps to deploy the Bicep templates:

## Prerequisites

1. **Install Azure CLI**: Ensure you have the Azure CLI installed. You can download it from [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

2. **Install Bicep CLI**: Install the Bicep CLI by running the following command:
  ```sh
  az bicep install
  ```

3. **Login to Azure**: Log in to your Azure account using the Azure CLI:
  ```sh
  az login
  ```

## Steps to Deploy

1. **Navigate to the Directory**: Change to the directory containing your Bicep templates.
  ```sh
  cd /path/to/your/bicep/templates
  ```

2. **Validate the Bicep Template**: Validate your Bicep template to ensure there are no errors.
  ```sh
  az deployment group validate --resource-group <your-resource-group> --template-file <your-template>.bicep
  ```

3. **Deploy the Bicep Template**: Deploy the Bicep template to your resource group.
  ```sh
  az deployment group create --resource-group <your-resource-group> --template-file <your-template>.bicep
  ```

4. **Check Deployment Status**: Verify the deployment status.
  ```sh
  az deployment group show --name <deployment-name> --resource-group <your-resource-group>
  ```

Replace `<your-resource-group>`, `<your-template>.bicep`, and `<deployment-name>` with your actual resource group name, Bicep template file name, and deployment name respectively.

## Example

Here is an example of deploying a Bicep template named `main.bicep` to a resource group named `MyResourceGroup`:

```sh
cd /workspaces/Festive-Tech-Calander/2024/bicep-templates
az deployment group validate --resource-group MyResourceGroup --template-file main.bicep
az deployment group create --resource-group MyResourceGroup --template-file main.bicep
az deployment group show --name mainDeployment --resource-group MyResourceGroup
```

Follow these steps to successfully deploy your Bicep templates.