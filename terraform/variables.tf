variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
}

variable "lf_training_username" {
  description = "LF Training Resources Username"
  type        = string
}

variable "lf_training_password" {
  description = "LF Training Resources Password"
  type        = string
}
