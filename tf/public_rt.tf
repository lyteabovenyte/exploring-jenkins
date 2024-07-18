# IGW maps the instance's private IP with an associated public or Elastic IP 
# and then route traffic outside the subnet to the internet
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.management.id

    tags = {
        Name = "igw_${var.vpc_name}"
        Author = var.author
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.management.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "public_rt_${var.vpc_name}"
        Author = var.author
    }
}

resource "aws_route_table_association" "public" {
    count = var.public_subnets_count
    subnet_id = element(aws_subnet.public_subnets.*.id, count.index)
    route_table_id = aws_route_table.public_rt.id
}