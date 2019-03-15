#------------------------------------------------------------------------------
#  output
#------------------------------------------------------------------------------

output "elb_public_id" {
  value = "${aws_alb.api.arn_suffix}"
}

output "asg_id" {
  value = "${aws_autoscaling_group.api.id}"
}

output "target_group" {
  value = "${aws_alb_target_group.api.name}"
}