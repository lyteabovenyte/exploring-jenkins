resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.${count.index * 2 + 1}.0/24"
  availability_zone = element(var.availability_zones, count.index)

  # specify true to indicate that instances launched into the subnet
  # should be assigned a public IP address
  map_public_ip_on_launch = true

  count = var.public_subnets_count

  tags = {
    Name   = "public_10.0.${count.index * 2 + 1}.0_${element(var.availability_zones, count.index)}"
    Author = var.author
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id                  = aws_vpc.management.id
  cidr_block              = "10.0.${count.index * 2}.0/24"
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  count = var.private_subnets_count

  tags = {
    Name   = "private_10.0.${count.index * 2}.0_${element(var.availability_zones, count.index)}"
    Author = var.author
  }
}