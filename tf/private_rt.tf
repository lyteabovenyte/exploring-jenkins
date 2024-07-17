resource "aws_eip" "nat" {
    vpc = true

    tags = {
        Name = "eip-nat_${var.vpc_name}"
        Author = var.author
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = element(aws_subnet.public_subnets.*.id, 0)

    tags = {
        Name = "nat_${var.vpc_name}"
        Author = var.author
    }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.management.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "private_rt_${var.vpc_name}"
        Author = var.author
    }
}

resource "aws_route_table_association" "private" {
    count = var.private_subnets_count
    subnet_id = element(aws_subnet.private_subnets.*.id, count.index)
    route_table_id = aws_route_table.private_rt.id
}