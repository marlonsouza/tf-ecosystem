module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "traffic-event-bus-${var.environment}"

  tags = {
    Name = "traffic-event-bus-${var.environment}"
  }
}