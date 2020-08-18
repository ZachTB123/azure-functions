resource random_integer rand {
  min = 100
  max = 999
}

resource azurerm_resource_group rg {
  name     = "function-app-deploy${random_integer.rand.result}"
  location = "centralus"
}

resource azurerm_application_insights ai {
  name                = "func-app-deploy-ai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "other"
}

resource azurerm_storage_account func_storage {
  name                      = "funcappsa${random_integer.rand.result}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  allow_blob_public_access  = false
}

resource azurerm_app_service_plan plan {
  name                = "func-app-deploy-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource azurerm_function_app func {
  name                       = "func-app-deploy"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key
  enabled                    = true
  version                    = "3.0.14191.0"
  https_only                 = true

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key
    SCM_DO_BUILD_DURING_DEPLOYMENT = false
    WEBSITE_RUN_FROM_PACKAGE       = 1
  }

  site_config {
    min_tls_version = 1.2
    ftps_state      = "Disabled"
  }
}

data archive_file zip {
  type        = "zip"
  source_dir  = "./_golang/azure_functions/deploy"
  output_path = "./zip/func.zip"
}

# One time delay before publishing code to the function
resource null_resource deploy_func_code_dependency {
  provisioner local-exec {
    command = "sleep 30"
  }

  depends_on = [
    azurerm_function_app.func
  ]
}

resource null_resource deploy {
  triggers = {
    build_id = data.archive_file.zip.output_md5 # redeploy app code when zip md5 changes
  }

  provisioner local-exec {
    command = "curl -X POST -u \\${azurerm_function_app.func.site_credential[0].username}:${azurerm_function_app.func.site_credential[0].password} --data-binary @${data.archive_file.zip.output_path} https://${azurerm_function_app.func.name}.scm.azurewebsites.net/api/zipdeploy"
  }

  depends_on = [
    null_resource.deploy_func_code_dependency
  ]
}
