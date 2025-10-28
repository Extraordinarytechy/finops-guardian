variable "sender_email" {
  description = "The verified SES email address for sending reports. Must be in us-east-1."
  type        = string
}

variable "recipient_email" {
  description = "The email address to receive cost reports."
  type        = string
}

variable "organization_root_id" {
  description = "The AWS Organization Root ID or OU ID to attach the SCP. (e.g. 'r-xxxx' or 'ou-xxxx-xxxxxxxx')"
  type        = string
  default     = null 
}