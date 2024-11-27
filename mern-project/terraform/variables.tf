# variables.tf

# AWS Region for the resources
variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-west-2" # You can adjust this based on your preference
}

# VPC Configuration
variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = "my-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# EKS Cluster Configuration
variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.21"
}

variable "node_desired_capacity" {
  description = "The desired number of worker nodes in the EKS cluster."
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "The maximum number of worker nodes in the EKS cluster."
  type        = number
  default     = 5
}

variable "node_min_capacity" {
  description = "The minimum number of worker nodes in the EKS cluster."
  type        = number
  default     = 1
}

variable "node_instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the EC2 key pair to allow SSH access."
  type        = string
}

# S3 Bucket Configuration
variable "s3_bucket_name" {
  description = "The name of the S3 bucket for storing artifacts."
  type        = string
  default     = "my-artifacts-bucket"
}

# Security Group Configuration
variable "security_group_name" {
  description = "The name of the security group for the EKS nodes."
  type        = string
  default     = "eks-node-sg"
}
