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
    ansible = {
      source  = "ansible/ansible"
      version = "1.5.0"
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
  endpoint  = var.db_endpoint
  api_token = var.db_api_token

  ssh {
    username = var.db_user    # 1. This must be explicit (your error had user "")
    agent    = true      # 2. Instructs the provider to check your local ssh-agent
  }
  # Default to `true` unless you have TLS working within your pve setup
  insecure = false
}

# data "local_file" "ssh_public_key" {
#   filename = "./id_rsa.pub"
# }

resource "proxmox_virtual_environment_vm" "palworld" {
  count     = 1
  vm_id     = 200 + count.index
  name      = "palworld${count.index}"
  node_name = "enterprise"
  stop_on_destroy = true
  reboot = true
  reboot_after_update = true

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
    # datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "192.168.20.${200 + count.index}/24"
        gateway = "192.168.20.1"
      }
    }

#     user_account {
#       username = "exampleuser"
#       keys     = [trimspace(data.local_file.ssh_public_key.content)]
#     }
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 16384
  }

  connection {
    type = "ssh"
    user = "vmadmin"
    #private_key = file("~/.ssh/id_rsa")
    host = "192.168.20.${200 + count.index}"
    agent = true
    timeout = "7m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'SSH is ready for Ansible!'"]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '192.168.20.${200 + count.index},' -u vmadmin ~/ansible_quickstart/install_steam.yml"
  }

    provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '192.168.20.${200 + count.index},' -u vmadmin ~/ansible_quickstart/install_palworld.yml"
  }
}


data "local_file" "ssh_public_key" {
  filename = "../.ssh/id_rsa.pub"
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"

  source_raw {
    data = <<-EOF
    #cloud-config
#    hostname: test-ubuntu
    timezone: America/Detroit
    users:
      - default
      - name: vmadmin
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "user-data-cloud-config.yaml"
  }
}

# resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
#   count      = 1
#   name       = "test-ubuntu${count.index}"
#   node_name  = "enterprise"
#   vm_id      = 300 + count.index
#
#   # should be true if qemu agent is not installed / enabled on the VM
#   stop_on_destroy = true
#
#   initialization {
#
#     ip_config {
#       ipv4 {
#         address = "192.168.20.${20 + count.index}/24"
#         gateway = "192.168.20.1"
#       }
#     }
#
#     user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
#   }
#
#   disk {
#     datastore_id = "local-lvm"
#     import_from  = proxmox_download_file.ubuntu_cloud_image.id
#     interface    = "virtio0"
#     iothread     = true
#     discard      = "on"
#     size         = 20
#   }
#
#   network_device {
#     bridge   = "vmbr0"
#     vlan_id  = 20
#     firewall = true
#   }
#
# }

resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = "zfs-iso"
  node_name    = "enterprise"
  url          = "https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "resolute-server-cloudimg-amd64.qcow2"
}
