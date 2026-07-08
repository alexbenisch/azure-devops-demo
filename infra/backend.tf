terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote State im Azure Storage Account.
  # Anlegen einmalig out-of-band (siehe scripts/bootstrap.sh) — der State selbst
  # darf nicht per Terraform verwaltet werden (Henne-Ei-Problem).
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatedemo"
    container_name       = "tfstate"
    key                  = "demo.terraform.tfstate"
  }
}
