resource "aws_lb" "app-alb" {
  name                       = "${local.name_prefix}-APP-ALB"
  internal                   = true
  load_balancer_type         = "application"
  idle_timeout               = 600
  security_groups            = [aws_security_group.app-alb-sg.id]
  subnets                    = [aws_subnet.subnet-public.id, aws_subnet.subnet-private.id]
  enable_deletion_protection = false
  tags                       = merge({ "Name" = "${local.name_prefix}-APP-ALB" }, local.default_tags)
}

resource "aws_lb_target_group" "app-tg" {
  name        = "${local.name_prefix}-APP-TG"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"
  tags        = merge({ "Name" = "${local.name_prefix}-APP-LB-TG" }, local.default_tags)
  #Check changes name
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  #Check service available
  health_check {
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "app-http-listener" {
  load_balancer_arn = aws_lb.app-alb.arn
  port              = 80
  protocol          = "HTTP"

  #Redirection default
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn

  }
}

