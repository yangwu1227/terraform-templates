# Get available AZs from AWS
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Calculate VPC prefix length for adaptive sizing, e.g., extracts 16 from 10.0.0.0/16
  vpc_prefix = tonumber(split("/", var.vpc_cidr)[1])

  # Calculate number of bits needed for AZ allocation
  # For 2 AZs we need 1 bit, for 3 - 4 AZs we need 2 bits
  az_bits = ceil(log(length(local.azs), 2))

  # Define subnet sizes based on VPC size (adaptive approach)
  # These ensure subnets are appropriately sized for the VPC
  subnet_sizing = {
    # Examples: /16 VPC -> /20 private (4 bits), /20 VPC -> /24 private (4 bits), /24 VPC -> /26 private (2 bits)
    private_bits = local.vpc_prefix <= 16 ? 4 : (local.vpc_prefix <= 20 ? 4 : 2)
    # Examples: /16 VPC -> /24 public (8 bits), /20 VPC -> /27 public (7 bits), /24 VPC -> /28 public (4 bits)
    public_bits = local.vpc_prefix <= 16 ? 8 : (local.vpc_prefix <= 20 ? 7 : 4)
  }

  # Example: /16 VPC + 4 bits = /20 private subnets, /16 VPC + 8 bits = /24 public subnets
  private_prefix = local.vpc_prefix + local.subnet_sizing.private_bits
  public_prefix  = local.vpc_prefix + local.subnet_sizing.public_bits

  # Private subnets (/20) start at the beginning of VPC range
  # Example for /16 VPC with 2 AZs: creates 10.0.0.0/20 (index 0) and 10.0.16.0/20 (index 1)
  private_subnets = [
    for i, _ in local.azs :
    cidrsubnet(var.vpc_cidr, local.subnet_sizing.private_bits, i)
  ]

  # Public subnets (/24) start right after private subnets
  # Each /20 private subnet spans 16 /24 blocks (2^(24 - 20) = 16)
  # Example: 2 AZs with /20 private subnets consume blocks 0 - 31 (16 x 2 blocks), so public /24s start at block 32
  # This places public subnets at 10.0.32.0/24 (index 32) and 10.0.33.0/24 (index 33)
  public_base_offset = floor(
    length(local.azs) * pow(2, local.subnet_sizing.public_bits - local.subnet_sizing.private_bits)
  )

  public_subnets = [
    for i, _ in local.azs :
    cidrsubnet(var.vpc_cidr, local.subnet_sizing.public_bits, local.public_base_offset + i)
  ]

  # Calculate IP utilization for tagging (32 is the total number of bits in IPv4)
  total_ips_allocated = (
    # Private IPs
    length(local.azs) * pow(2, 32 - local.private_prefix) +
    # Public IPs
    length(local.azs) * pow(2, 32 - local.public_prefix)
  )
  vpc_total_ips       = pow(2, 32 - local.vpc_prefix)
  utilization_percent = (local.total_ips_allocated / local.vpc_total_ips) * 100

  # Example result: {"0" => {cidr = "10.0.32.0/24", az = "us-east-1a"}, "1" => {cidr = "10.0.33.0/24", az = "us-east-1b"}}
  public_subnet_map = {
    for i, cidr in local.public_subnets :
    tostring(i) => { cidr = cidr, az = local.azs[i] }
  }
  private_subnet_map = {
    for i, cidr in local.private_subnets :
    tostring(i) => { cidr = cidr, az = local.azs[i] }
  }
}


resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_prefix}_vpc"
    Utilization = "${local.utilization_percent}%"
  }
}

# Internet gateway and attachment
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}_igw"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}_public_subnet_${each.key}"
    Tier = "public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_prefix}_private_subnet_${each.key}"
    Tier = "private"
  }
}

# NAT gateways (provisioned in public subnets)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"

  tags = {
    Name = "${var.project_prefix}_eip_nat_${each.key}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  allocation_id = aws_eip.nat[each.key].id

  tags = {
    Name = "${var.project_prefix}_nat_${each.key}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Single public route table, associated by all public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}_public_rtb"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables and routes, one for each private subnet
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}_private_rtb_${each.key}"
  }
}

resource "aws_route" "private_default" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
