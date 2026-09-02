terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.24.0"
    }
  }
}


provider "cloudflare" {
#https://registry.terraform.io/providers/cloudflare/cloudflare/latest
  # Configuration options
}

provider "proxmox" {
#https://registry.terraform.io/providers/bpg/proxmox/latest
  # Configuration options
  endpoint = var.db_endpoint
  api_token = var.db_api_token
  # Default to `true` unless you have TLS working within your pve setup
  insecure = false
}

# data "local_file" "ssh_public_key" {
#   filename = "./id_rsa.pub"
# }

resource "proxmox_virtual_environment_vm" "my_vm" {
  name      = "my-vm"
  node_name = "enterprise"
  stop_on_destroy = true

  clone {
    vm_id = 130 # replace with the numeric ID of your template VM in Proxmox
    full = true
  }

  agent {
    # NOTE: The agent is installed and enabled as part of the cloud-init configuration in the template VM, see cloud-config.tf
    # The working agent is *required* to retrieve the VM IP addresses.
    # If you are using a different cloud-init configuration, or a different clone source
    # that does not have the qemu-guest-agent installed, you may need to disable the `agent` below and remove the `vm_ipv4_address` output.
    # See https://bpg.sh/docs/resources/virtual_environment_vm#qemu-guest-agent for more details.
    enabled = true
  }

  initialization {
    # uncomment and specify the datastore for cloud-init disk if default `local-lvm` is not available
     datastore_id = "local-lvm"

#     ip_config {
#       ipv4 {
#         address = "192.168.1.233/24"
#         gateway = "192.168.1.1"
#       }
#     }

#     user_account {
#       username = "exampleuser"
#       keys     = [trimspace(data.local_file.ssh_public_key.content)]
#     }
  }
}
