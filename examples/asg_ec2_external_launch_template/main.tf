provider "aws" {
  region = "eu-west-1"

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

#######################
# Launch template
# (сreating it outside of the module for example)
#######################
resource "aws_launch_template" "this" {
  name_prefix = "my-launch-template-"
  image_id    = data.aws_ami.amazon_linux.id

  lifecycle {
    create_before_destroy = true
  }
}

module "example" {
  source = "../../"

  name = "example-with-ec2-external-lt"

  # Use of existing launch template (created outside of this module)
  launch_template = aws_launch_template.this.name

  create_lt = false

  recreate_asg_when_lt_changes = true

  # Auto scaling group
  asg_name                  = "example-asg"
  vpc_zone_identifier       = data.aws_subnets.all.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }

  instance_types = [
    { instance_type = "t2.micro" },
    { instance_type = "t3.micro" }
  ]
}
