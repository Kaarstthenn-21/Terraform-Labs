#create private key
resource "tls_private_key" "app-private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#private key pair
resource "aws_key_pair" "generated-key" {
  key_name   = "APP-KEY"
  public_key = tls_private_key.app-private-key.public_key_openssh
}

#get ami recent
data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

output "test" {
  value = data.aws_ami.ubuntu
}

#prepare receta

resource "aws_launch_configuration" "app-launch-configuration" {
  name_prefix   = "${local.name_prefix}-APP-LC"
  image_id      = data.aws_ami.ubuntu.image_id
  instance_type = var.instance_type
  # user_data = ""
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.app_instance_profile.name
  security_groups             = [aws_security_group.app-sg.id]
  key_name                    = aws_key_pair.generated-key.key_name

  root_block_device {
    volume_size           = "60"
    volume_type           = "gp2"
    delete_on_termination = true
  }
  #To High availability
  lifecycle {
    create_before_destroy = true
  }
}

#Create AutoScalingGroup

resource "aws_autoscaling_group" "app-asg" {
  name_prefix          = "${local.name_prefix}-APP"
  launch_configuration = aws_launch_configuration.app-launch-configuration.id
  vpc_zone_identifier  = [aws_subnet.subnet-private.id, aws_subnet.subnet-public.id]
  min_size             = "2"
  max_size             = "4"
  health_check_type    = "EC2"

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "App-ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_attachment" "asg-attachment" {
  autoscaling_group_name = aws_security_group.app-sg.name
  lb_target_group_arn    = aws_lb_target_group.app-tg.arn
}
