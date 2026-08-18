terraform {
  required_version = ">= 1.5.0"
}

variable "name" {
  description = "Name for the resource/module instance."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "environment" {
  description = "Environment identifier such as dev, test, or prod."
  type        = string
}

locals {
  common_labels = {
    name        = var.name
    environment = var.environment
  }
}

# Add provider-specific resources here. Keep credentials outside Terraform code
# and prefer variables/data sources/identity mechanisms over hard-coded values.

output "name" {
  description = "Normalized name supplied to the module."
  value       = var.name
}
