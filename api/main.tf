#------------------------------------------------------------------------------
#  main.tf
#------------------------------------------------------------------------------

provider "aws" {
  profile = "${var.account}"
  region  = "ap-southeast-1"
}

#------------------------------------------------------------------------------
#   Security Groups
#------------------------------------------------------------------------------

resource "aws_security_group" "apialb" {
  name_prefix = "${var.env}-${var.project}-alb-"
  description = "${var.env} ${var.project} ALB"
  vpc_id      = "${data.aws_vpc.main.id}"

  tags {
    Name        = "${var.env}:${var.project}:alb"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.ipaddress}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.env}-${var.project}-alb"
  }
}

resource "aws_security_group" "apisrv" {
  name_prefix = "${var.env}-${var.project}-"
  description = "${var.env} ${var.project}"
  vpc_id      = "${data.aws_vpc.main.id}"

  tags {
    Name        = "${var.env}:${var.project}"
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.apialb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------------------------------------------------------------------------------
#   Roles, Profiles and Policies
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "api_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name_prefix        = "${var.env}-${var.project}-"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.api_role.json}"
}

resource "aws_iam_instance_profile" "api" {
  name_prefix = "${var.env}-${var.project}-"
  path        = "/"
  role        = "${aws_iam_role.api.name}"
}

data "aws_iam_policy_document" "api_policy" {
  statement {
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "api" {
  name_prefix = "${var.env}-${var.project}"
  path        = "/"
  description = "${var.env} ${var.project} policy"
  policy      = "${data.aws_iam_policy_document.api_policy.json}"
}

resource "aws_iam_role_policy_attachment" "api" {
  role       = "${aws_iam_role.api.name}"
  policy_arn = "${aws_iam_policy.api.arn}"
}

#------------------------------------------------------------------------------
#   ALB
#------------------------------------------------------------------------------

resource "aws_alb" "api" {
  name            = "${var.env}-${var.project}"
  subnets         = ["${data.aws_subnet.tier1.*.id}"]
  security_groups = ["${aws_security_group.apialb.id}"]
  internal        = "${var.alb_api_is_internal}"

  tags {
    Name        = "${var.env}-${var.project}-ALB"
  }

  access_logs {
    bucket  = "${var.log-bucket}"
    prefix  = "${var.project}"
    enabled = "${var.enable_logging}"
  }
}

resource "aws_alb_target_group" "api_target_group" {
  name                 = "${var.env}-${var.project}"
  vpc_id               = "${data.aws_vpc.main.id}"
  port                 = "${var.backend_port}"
  protocol             = "HTTP"

  health_check {
    interval            = "10"
    path                = "${var.health_check_path}"
    port                = "traffic-port"
    healthy_threshold   = "3"
    unhealthy_threshold = "5"
    timeout             = "5"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  tags {
    Name        = "${var.env}-${var.project}-ALB"
  }

}

resource "aws_alb_listener" "frontend_http" {
  load_balancer_arn = "${aws_alb.api.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.api_target_group.arn}"
    type             = "forward"
  }

}

#------------------------------------------------------------------------------
# Launch Config 
#------------------------------------------------------------------------------

resource "aws_launch_configuration" "api" {
  name_prefix                 = "${var.env}-${var.project}-${var.app_version}"
  image_id                    = "${data.aws_ami.api.id}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = "false"
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.api.name}"
  security_groups             = [ "${data.aws_security_group.default.id}", "${aws_security_group.apisrv.id}"]

  root_block_device           { volume_size = 20 }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Autoscaling group
#------------------------------------------------------------------------------

resource "aws_autoscaling_group" "api" {
  name_prefix           = "${var.env}-${var.project}-${var.app_version}"
  min_size              = "${var.stackMinSize}"
  max_size              = "${var.stackMaxSize}"
  vpc_zone_identifier   = [ "${ data.aws_subnet.tier2.*.id }" ]
  launch_configuration  = "${aws_launch_configuration.api.name}"
  desired_capacity      = "${ var.stackDesiredSize }"
  target_group_arns        = [ "${aws_alb_target_group.api_target_group.arn}" ]
  health_check_type     = "ELB"


  tag {
    key                 = "Name"
    value               = "${var.env}-${var.project}-${var.app_version}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}



#------------------------------------------------------------------------------
#   Route53 Domain - ELB Mapping
#------------------------------------------------------------------------------

