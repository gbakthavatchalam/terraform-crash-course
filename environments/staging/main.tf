module "staging" {
  source = "../modules/web"

  environment = {
    "name": "staging",
    "network_prefix": "10.192."
  }

  instance_type = "t3.nano""
  asg_min       = 1
  asg_max       = 1
}