# Primary VPC
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-primary-vpc"
    Environment = var.environment
  }
}

# Secondary VPC
resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-secondary-vpc"
    Environment = var.environment
  }
}

# Primary Subnets
resource "aws_subnet" "primary_public" {
  count                   = length(var.primary_azs)
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, count.index)
  availability_zone       = var.primary_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-primary-public-${count.index + 1}"
  }
}

resource "aws_subnet" "primary_private" {
  count             = length(var.primary_azs)
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet(var.primary_vpc_cidr, 8, count.index + length(var.primary_azs))
  availability_zone = var.primary_azs[count.index]

  tags = {
    Name = "${var.project_name}-primary-private-${count.index + 1}"
  }
}

# Secondary Subnets
resource "aws_subnet" "secondary_public" {
  count                   = length(var.secondary_azs)
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, count.index)
  availability_zone       = var.secondary_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-secondary-public-${count.index + 1}"
  }
}

resource "aws_subnet" "secondary_private" {
  count             = length(var.secondary_azs)
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet(var.secondary_vpc_cidr, 8, count.index + length(var.secondary_azs))
  availability_zone = var.secondary_azs[count.index]

  tags = {
    Name = "${var.project_name}-secondary-private-${count.index + 1}"
  }
}

# Internet Gateways
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name = "${var.project_name}-primary-igw"
  }
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name = "${var.project_name}-secondary-igw"
  }
}

# NAT Gateways
resource "aws_eip" "primary_nat" {
  provider = aws.primary
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-primary-nat-eip"
  }
}

resource "aws_nat_gateway" "primary" {
  provider      = aws.primary
  allocation_id = aws_eip.primary_nat.id
  subnet_id     = aws_subnet.primary_public[0].id
  
  tags = {
    Name = "${var.project_name}-primary-nat"
  }
}

resource "aws_eip" "secondary_nat" {
  provider = aws.secondary
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-secondary-nat-eip"
  }
}

resource "aws_nat_gateway" "secondary" {
  provider      = aws.secondary
  allocation_id = aws_eip.secondary_nat.id
  subnet_id     = aws_subnet.secondary_public[0].id
  
  tags = {
    Name = "${var.project_name}-secondary-nat"
  }
}

# Route Tables
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }
  
  tags = {
    Name = "${var.project_name}-primary-public-rt"
  }
}

resource "aws_route_table" "primary_private" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary.id
  }
  
  tags = {
    Name = "${var.project_name}-primary-private-rt"
  }
}

resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }
  
  tags = {
    Name = "${var.project_name}-secondary-public-rt"
  }
}

resource "aws_route_table" "secondary_private" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secondary.id
  }
  
  tags = {
    Name = "${var.project_name}-secondary-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "primary_public" {
  count          = length(var.primary_azs)
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public.id
}

resource "aws_route_table_association" "primary_private" {
  count          = length(var.primary_azs)
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private[count.index].id
  route_table_id = aws_route_table.primary_private.id
}

resource "aws_route_table_association" "secondary_public" {
  count          = length(var.secondary_azs)
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public[count.index].id
  route_table_id = aws_route_table.secondary_public.id
}

resource "aws_route_table_association" "secondary_private" {
  count          = length(var.secondary_azs)
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_private[count.index].id
  route_table_id = aws_route_table.secondary_private.id
}

# VPC Peering
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider      = aws.primary
  vpc_id        = aws_vpc.primary.id
  peer_vpc_id   = aws_vpc.secondary.id
  peer_region   = "us-west-2"
  auto_accept   = false
  
  tags = {
    Name = "primary-to-secondary-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "secondary_accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true
  
  tags = {
    Name = "secondary-accepter"
  }
}

# Add routes for VPC peering
resource "aws_route" "primary_to_secondary_public" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_public.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}

resource "aws_route" "primary_to_secondary_private" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_private.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}

resource "aws_route" "secondary_to_primary_public" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_public.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}

resource "aws_route" "secondary_to_primary_private" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_private.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}
# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

# Attach Flow Logs to VPC
resource "aws_flow_log" "main" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  vpc_id               = aws_vpc.primary.id
  traffic_type         = "ALL"
}
