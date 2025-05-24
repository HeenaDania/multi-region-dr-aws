# Common Variables
variable "project_name" {
  description = "Name of the project"
  default     = "multi-region-dr"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  default     = "prod"
}

# VPC Variables
variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary VPC"
  default     = "10.1.0.0/16"
}

variable "primary_azs" {
  description = "Availability zones in primary region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "secondary_azs" {
  description = "Availability zones in secondary region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_primary" {
  description = "AMI ID for primary region"
  default     = "ami-0e58b56aa4d64231b"
}

variable "ami_secondary" {
  description = "AMI ID for secondary region"
  default     = "ami-0ec1ab28d37d960a9" 
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  default     = "multiregiondb"
}

variable "db_username" {
  description = "Database username"
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

# Route53 Variables
variable "domain_name" {
  description = "Domain name for the application"
  default     = "heenadania.com "  
}
