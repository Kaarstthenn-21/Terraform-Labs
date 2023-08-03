resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = merge({
    "Name" = "${local.name_prefix}-VPC"
    },
    local.default_tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge({
    "Name" = "${local.name_prefix}-IGW"
    },
    local.default_tags
  )
}

resource "aws_subnet" "subnet-public" {
  map_public_ip_on_launch = true
  availability_zone       = element(var.az_name, 0)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.subnet_cidr_blocks, 0)
  tags = merge({
    "Name" = "${local.name_prefix}-SUBNET-AZ-A"
    },
    local.default_tags
  )
}

resource "aws_subnet" "subnet-private" {
  map_public_ip_on_launch = false
  availability_zone       = element(var.az_name, 1)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.subnet_cidr_blocks, 1)
  tags = merge({
    "Name" = "${local.name_prefix}-SUBNET-AZ-B"
    },
    local.default_tags
  )
}

resource "aws_eip" "app-eip" {

}

resource "aws_nat_gateway" "nat-gateway" {
  subnet_id     = aws_subnet.subnet-public.id
  allocation_id = aws_eip.app-eip.id
  tags = merge({
    "Name" = "${local.name_prefix}-NGW"
    },
    local.default_tags
  )
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    tags = merge({
      "Name" = "${local.name_prefix}-PUBLIC-RT"
      },
      local.default_tags
    )
  }
}
