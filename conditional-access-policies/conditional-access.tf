##############################################################
### Providers:

terraform {
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "=1.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
  }
}
provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  #resource_provider_registrations = "none" # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}
provider "azapi" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
##############################################################
### Conditional access - Allowed Countries:

resource "azuread_conditional_access_policy" "Allowed_Countries" {
  display_name = "Allowed Countries"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
      excluded_locations = [azuread_named_location.Allowed_Countries[*].id]
    }

    platforms {
      included_platforms = ["all"]
    }

    users {
      included_users = ["All"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}
##############################################################
### Conditional Access policy - "AVD - Prompt for MFA"

resource "azuread_conditional_access_policy" "prompt_for_mfa" {
  display_name = "AVD - Prompt for MFA"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types    = ["browser", "mobileAppsAndDesktopClients"]
    sign_in_risk_levels = ["medium"]
    user_risk_levels    = ["medium"]

    applications {
      included_applications = [
        "9cdead84-a844-4324-93f2-b2e6bb768d07", # Azure Virtual Desktop
        "a4a365df-50f1-4397-bc59-1a1564b8bb9c", # Microsoft Remote Desktop
        "270efc09-cd0d-444b-a71f-39af4910ec45", # Windows Cloud Login
      ]
      excluded_applications = []
    }

    users {
      included_groups = ["All"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa", "block"]
  }

  session_controls {
    sign_in_frequency_period = "hours"
    sign_in_frequency        = 1
  }
}
##############################################################
### Named Location - Allowed Countries:

resource "azuread_named_location" "Allowed_Countries" {
  display_name = "Allowed Countries"
  country {
    countries_and_regions = [
      "GB",
    ]
    include_unknown_countries_and_regions = false
  }
}
