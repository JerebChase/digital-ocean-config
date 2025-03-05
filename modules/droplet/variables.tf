variable "project_id" {
  description = "The id of the digital ocean project"
  type        = string
}

variable "port_client_id" {
  description = "The Port client id"
  type        = string
}

variable "port_client_secret" {
  description = "The Port client secret"
  type        = string
}

variable "aws_access_key" {
  description = "The aws access key for crossplane"
  type        = string 
}

variable "aws_secret_key" {
  description = "The aws secret key for crossplane"
  type        = string 
}