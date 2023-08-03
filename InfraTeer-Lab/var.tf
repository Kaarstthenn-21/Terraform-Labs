variable "aws_region" {
  description = "us-east-1"
  default     = ""
}

variable "env" {
  type    = string
  default = "Infra"
}

variable "product" {
  type    = string
  default = ""
}

variable "dir_type" {
  type    = string
  default = "SimpleAD"
}

variable "az_name" {
  type    = list(string)
  default = [""]
}

variable "vpc_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_cidr_blocks" {
  type    = list(string)
  default = [""]
}

variable "domain_name" {

}

variable "allocated_storage" {

}

variable "engine_name" {

}

variable "engine_version" {

}

variable "db_instance" {

}

variable "db_name" {

}

variable "username" {

}

variable "password" {

}





