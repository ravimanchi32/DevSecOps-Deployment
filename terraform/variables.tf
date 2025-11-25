variable "region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  default     = "my-eks-cluster"
}

variable "node_group_instance" {
  description = "EC2 instance type for EKS Worker Nodes"
  # Cheapest possible instance supported by EKS
  default     = "t3.small"
}

variable "desired_size" {
  description = "Number of desired nodes"
  default     = 1
}

variable "min_size" {
  description = "Minimum number of nodes"
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  default     = 2
}
