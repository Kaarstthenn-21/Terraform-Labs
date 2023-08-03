provider "aws" {
  region = "us-east-1"
}

#Define instance EC2

resource "aws_instance" "linux2" {
  instance_type = "t2.micro"
  ami           = "ami-09538990a0c4fe9be"

  tags = {
    Name = "HelloWorld"
  }
    #Assign SG to Instance
  vpc_security_group_ids = [aws_security_group.instance-sg.id]

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y amazon-linux-extras
                sudo amazon-linux-extras install nginx1 -y
                sudo amazon-linux-extras list | grep nginx
                sudo systemctl start nginx.service
                sudo systemctl enable httpd.service                
  EOF

}

#Define Security Group

resource "aws_security_group" "instance-sg" {
  name = "terraform-example-sg"
    #Inboubnd rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    #Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

