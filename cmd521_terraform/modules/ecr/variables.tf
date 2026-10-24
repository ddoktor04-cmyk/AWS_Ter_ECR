###############################################################################
# MODULE: ecr                                                                 #
# Inputs for the ECR repository                                               #
###############################################################################

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "CMD521"
}

variable "environment" {
  description = "Environment name (dev/staging/prod) applied as a tag"
  type        = string
  default     = "dev"
}

variable "repository_name" {
  description = "Name of the ECR repository (globally unique within the account/region)"
  type        = string
  default     = "todoai"
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable ECR basic image scanning on every push"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository even if it contains images (demo convenience)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to every resource that supports tagging"
  type        = map(string)
  default     = { ManagedBy = "Terraform" }
}
