locals {
  tags_asg_format = null_resource.tags_as_list_of_maps.*.triggers
  lt_version      = var.lt_version != null ? var.lt_version : var.use_created_lt_latest_version ? element(concat(aws_launch_template.this.*.latest_version, ["$Latest"]), 0) : "$Latest"
}

resource "null_resource" "tags_as_list_of_maps" {
  count = length(keys(var.tags_as_map))

  triggers = {
    key                 = keys(var.tags_as_map)[count.index]
    value               = values(var.tags_as_map)[count.index]
    propagate_at_launch = true
  }
}
