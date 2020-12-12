


locals {
    required_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = var.fn_settings.runtime_type
    }
    combined_settings = merge(local.required_settings, var.fn_settings.app_settings)
}


# This will deploy an Azure Function to the target Resource Group / App Service Plan
resource "azurerm_function_app" "function_app" {
  name                      = var.fn_settings.name
  location                  = var.environment.location
  resource_group_name       = var.environment.resource_group_name
  app_service_plan_id       = var.host_settings.plan_id
  storage_connection_string = var.host_settings.storage_connection_string
  version                   = var.fn_settings.runtime_version

  app_settings = local.combined_settings

  site_config {

    pre_warmed_instance_count = 1
    
  }

  tags = {
    app = var.environment.app_name
    env = var.environment.env_name
  }

}

# This will obtain the Azure Function's Key that can be used to integrate with the Azure Function by API Management
resource "azurerm_template_deployment" "azfn_function_key" {
  name = "${var.fn_settings.name}-key-rgt"
  parameters = {
    "functionApp" = azurerm_function_app.function_app.name
  }
  resource_group_name    = var.environment.resource_group_name
  deployment_mode = "Incremental"

  template_body = <<BODY
  {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {
          "functionApp": {"type": "string", "defaultValue": ""}
      },
      "variables": {
          "functionAppId": "[resourceId('Microsoft.Web/sites', parameters('functionApp'))]"
      },
      "resources": [
      ],
      "outputs": {
          "functionkey": {
              "type": "string",
              "value": "[listkeys(concat(variables('functionAppId'), '/host/default'), '2018-11-01').functionKeys.default]"
              }
      }
  }
  BODY

  depends_on = [azurerm_function_app.function_app]
}

