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

variable "game_server_password" {
    description = "Palworld Server password"
    type = string
    sensitive = true
}

variable "game_admin_password" {
    description = "Palworld Server Admin Password"
    type = string
    sensitive = true
}
