#------------------------------------------------------------------------------
#terraform/ec2/data.tf
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
#   Region and Zones
#------------------------------------------------------------------------------

variable "suffixes" {
  default = {
    "0" = "a"
    "1" = "b"
    "2" = "c"
    "3" = "d"
  }
}

data "aws_region" "current" { }

data "aws_availability_zone" "zones" {
  count = "2"
  name  = "${data.aws_region.current.name}${lookup(var.suffixes, count.index)}"
}


#------------------------------------------------------------------------------
#   VPC and Subnets
#------------------------------------------------------------------------------

data "aws_vpc" "main" {
  tags {
    Name = "${var.account}-${data.aws_region.current.name}"
  }
}

data "aws_subnet" "tier1" {
  count             = 2
  vpc_id            = "${ data.aws_vpc.main.id }"
  availability_zone = "${ element( data.aws_availability_zone.zones.*.id, count.index ) }"

  tags {
    Tier = "1"
  }
}

data "aws_subnet" "tier2" {
  count             = 2
  vpc_id            = "${ data.aws_vpc.main.id }"
  availability_zone = "${ element( data.aws_availability_zone.zones.*.id, count.index ) }"

  tags {
    Tier = "2"
  }
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.main.id}"

  tags {
    Name = "${var.account}:${var.grp}:default"
  }
}

#------------------------------------------------------------------------------
#   AMI's
#------------------------------------------------------------------------------

# Most recent from the Build account
data "aws_ami" "api" {
  owners      = ["xxxxxxxxxxxxx"]
  name_regex  = "^${var.project}-${var.app_version}"
}




