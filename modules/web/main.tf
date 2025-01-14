data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "my_web_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name               = "${var.environment.name}-web}"
  cidr               = "${var.environment.network_prefix}.0.0/16"
  azs                = ["us-west-2a"]
  public_subnets     = ["${var.environment.network_prefix}.0.0/16"]

  tags = {
    "Name": "Terraform",
    "Environment": var.environment.name
  }
}

module "my_web_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.3.1"
  
  name = "${var.environment.name}-asg"
  min_size = var.asg_min
  max_size = var.asg_max
  vpc_zone_identifier = module.my_web_vpc.public_subnets
  target_group_arns   = module.my_web_alb.target_group_arns
  security_groups     = [module.my_web_security_group.security_group_id]
  instance_type       = var.instance_type
  image_id            = data.aws_ami.app_ami.id

}

module "my_web_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name               = "${var.environment.name}-web"
  load_balancer_type = "application"
  vpc_id             = module.my_web_vpc.vpc_id
  subnets            = module.my_web_vpc.public_subnets
  security_groups    = [module.my_web_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "web-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment.name
  }
}

module "my_web_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "${var.environment.name}-web"
  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  egress_rules = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/24"]
  egress_cidr_blocks = ["0.0.0.0/24"]
  vpc_id = module.my_web_vpc.vpc_id
}