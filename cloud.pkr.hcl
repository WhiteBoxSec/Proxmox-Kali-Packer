# Kali
# ---
# Packer create a Kali Linux cloud-init template on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}
variable "tailscale_key" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox-iso" "kali-full" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "WBS-Sec-Server-2"
    vm_id = "830"
    vm_name = "Kali-Packer-Test"
    template_description = "Kali-Packer-Test"
    # defines the OS
    os = "l26"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "local:iso/kali-linux-2023.3-installer-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    #iso_url = "https://cdimage.kali.org/kali-2023.3/kali-linux-2023.3-installer-netinst-amd64.iso"
    #iso_checksum = "sha256:0b0f5560c21bcc1ee2b1fef2d8e21dca99cc6efa938a47108bbba63bec499779"
    #iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "60G"
	# Only raw format supported on local-lvm storage
        format = "raw"
        storage_pool = "local-lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "2"
    
    # VM Memory Settings
    # Memory balloning settings to add memory on-demand
    ballooning_minimum = "2048"
    memory = "4096" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
	# Optional VLAN tag
	# vlan_tag = 99
    } 
    vga {
	type = "std"
	memory = 64
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER boot commands for unattended install
    boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "<esc><wait>",
    "install preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/cloud.cfg debian-installer=en_US auto locale=en_US kbd-chooser/method=us <wait>",
    "netcfg/get_hostname=kali-clientA netcfg/get_domain=local fb=false debconf/frontend=noninteractive console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us keyboard-configuration/xkb-keymap=us <wait>",
    "<enter><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "0.0.0.0"
    http_port_min = 8902
    http_port_max = 8902

    ssh_username = "kali"

    # (Option 1) Add your Password here
    ssh_password = "kali"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    # ssh_private_key_file = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "30m"
}

# Build Definition to create the VM Template
build {

    name = "kali"
    sources = ["source.proxmox-iso.kali-full"]

    # Add in tailscale to the template.
    provisioner "shell" {
        inline = [
	    "sudo apt install curl -y",
            "sudo curl -fsSL https://tailscale.com/install.sh | sh",
            "sudo apt update",
            "sudo apt install tailscale -y",
            "sudo tailscale up --authkey=${var.tailscale_key}"
        ]
    }
# Transfer cloud-init config file to VM
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Copy cloud-init file to proper location
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}
