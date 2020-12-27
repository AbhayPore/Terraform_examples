resource "aws_vpc" "app_vpc" {
	cidr_block = "10.0.0.0/16"
	tags = {
		vpc_type = "web"
	}
}
resource "aws_subnet" "app_pub_subnet" {
	vpc_id = aws_vpc.app_vpc.id
	cidr_block = "10.0.1.0/24"
	tags = {
		vpc_type = "web"
	}
}
resource "aws_internet_gateway" "app_igw"{
	vpc_id = aws_vpc.app_vpc.id
	tags = {
		vpc_type = "web"
	}
}
resource "aws_route_table" "app_route_table_pub" {
	vpc_id = aws_vpc.app_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.app_igw.id
	}
	tags = {
		vpc_type = "web"
	}
}
resource "aws_route_table_association" "app_route_association" {
	route_table_id = aws_route_table.app_route_table_pub.id
	subnet_id = aws_subnet.app_pub_subnet.id
}
resource "aws_security_group" "app_security_group" {
	vpc_id = aws_vpc.app_vpc.id
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress{
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks =["0.0.0.0/0"]
	}
}
resource "aws_instance" "app_instance" {
	subnet_id = aws_subnet.app_pub_subnet.id
	vpc_security_group_ids  = [aws_security_group.app_security_group.id]
	ami="ami-0be2609ba883822ec"
	instance_type="t2.micro"
	associate_public_ip_address = true
	key_name = "northremembers"
	user_data = <<-EOF
		#! /bin/bash
		sudo yum install -y httpd
		sudo systemctl start httpd
		sudo systemctl enable httpd
		echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
		EOF

}
output "web-app"{
	value=aws_instance.app_instance.public_ip
}