variable "deployment_prefix" {
  description = "Prefix for all resources"
  type        = string
}

# set vm priority to spot or regular 
variable "vm_priority" {
  description = "Priority for the VM"
  type        = string
  default     = "Spot"
}

variable "vm_username" {
  description = "Username for the VM"
  type        = string
  default     = "debian"
}

variable "ssh_public_key" {
  description = "SSH public key for the VM"
  type        = string
}
