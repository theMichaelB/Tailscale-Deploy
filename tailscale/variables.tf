variable "deployment_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_tshirt_size" {
  description = "T-shirt size for the VM"
  type        = string
  default     = "small"
}

variable "vm_size_map" {
  description = "Map of t-shirt sizes to Azure VM sizes"
  type        = map(string)
  default = {
    small  = "Standard_B2pts_v2"
    medium = "Standard_B2ts_v2"
    large  = "Standard_B4ms"
    xlarge = "Standard_B8ms"
  }
}

variable "vm_username" {
  description = "Username for the VM"
  type        = string
  default     = "debian"
}

# set vm priority to spot or regular 
variable "vm_priority" {
  description = "Priority for the VM"
  type        = string
  default     = "Spot"
}


variable "ssh_public_key" {
  description = "SSH public key for the VM"
  type        = string
}

variable "TAILSCALE_CLIENT_ID" {
  description = "Tailscale client ID"
  type        = string
}

variable "TAILSCALE_CLIENT_SECRET" {
  description = "Tailscale client secret"
  type        = string
}

variable "network_cidr_prefix" {
  description = "First three octets of the network CIDR range"
  type        = string
}
