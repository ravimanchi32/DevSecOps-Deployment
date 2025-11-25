variable "region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "my-eks-cluster"
}

variable "node_group_instance" {
  default = "t3.medium"
}

variable "desired_size" {
  default = 2
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 3
}

