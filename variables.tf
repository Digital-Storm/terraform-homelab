variable "db_endpoint" {
    description = "Proxmox Endpoint URL"
    type = string
    sensitive = false
}

variable "db_api_token" {
    description = "Proxmox Terraform Token"
    type = string
    sensitive = true
}

variable "db_user" {
    description = "Proxmox User Account"
    type = string
    sensitive = true
}
