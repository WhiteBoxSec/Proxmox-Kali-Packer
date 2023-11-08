# Proxmox-Kali-Packer
Packer template for creating Kali cloud-init image in Proxmox. 

This is for a Kali cloud-init image in Proxmox. The main Packer file also adds in Tailscale for use on internal penetration tests or remote access.

## Usage

Add your credentials to the credentials file.

How to create a new user and API key.

https://registry.terraform.io/providers/Telmate/proxmox/latest/docs


Validate the config 
```
packer validate -var-file=credentials.pkr.hcl kali-cloud.pkr.hcl
```

Build the image. It can take a while, be patient. 

```
packer build -var-file=credentials.pkr.hcl kali-cloud.pkr.hcl
```
