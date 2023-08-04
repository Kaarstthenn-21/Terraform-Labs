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

# Private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
    tags = merge({
      "Name" = "${local.name_prefix}-PRIVATE-RT"
      },
      local.default_tags
    )
  }
}


# Endpoint

resource "aws_vpc_endpoint" "s3-endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.public-route-table.id, aws_route_table.private-route-table.id]
}

# Associate Route tables with subnet

resource "aws_route_table_association" "public-association" {
  route_table_id = aws_route_table.public-route.table.id
  subnet_id      = aws_subnet.subnet-public.id
}

resource "aws_route_table_association" "private-association" {
  route_table_id = aws_route_table.private-route.table.id
  subnet_id      = aws_subnet.subnet-private.id
}

resource "aws_network_acl" "network-acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet-public.id, aws_subnet.subnet-private.id]
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 23
    to         = 23
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to         = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 23
    to         = 23
  }

  egress {
    protocol   = "tcp"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to         = 0
  }
  tags = merge({
    "Name" = "${local.name_prefix}-NETWORK-ACL"
    },
    local.default_tags
  )
}

#Security for Load Balancer

resource "aws_security_group" "app-alb-sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${local.name_prefix}-ALB-SG"

  ingress {
    from_port      = 80
    to_port        = 80
    protocol       = "tcp"
    security_group = [aws_security_group.app-sg.id]
  }
  ingress {
    from_port      = 443
    to_port        = 443
    protocol       = "tcp"
    security_group = [aws_security_group.app-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    "Name" = "${local.name_prefix}-SG-LB"
    },
    local.default_tags
  )
}

resource "aws_security_group" "app-sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${local.name_prefix}-SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-SG"
    },
    local.default_tags,
  )
}






