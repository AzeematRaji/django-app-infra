resource "aws_vpc" "django_app" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "django-app-vpc"
  })
}

resource "aws_internet_gateway" "django_app" {
  vpc_id = aws_vpc.django_app.id
  
  tags = merge(var.tags, {
    Name = "django-app-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.django_app.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "django-app-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.django_app.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "django-app-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)
  
  domain = "vpc"
  depends_on = [aws_internet_gateway.django_app]
  
  tags = merge(var.tags, {
    Name = "django-app-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "django_app" {
  count = length(var.public_subnet_cidrs)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "django-app-nat-gw-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.django_app]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.django_app.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django_app.id
  }
  
  tags = merge(var.tags, {
    Name = "django-app-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.django_app.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.django_app[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "django-app-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}