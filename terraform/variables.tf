locals {
  vpc = {
    name                     = "vpc-faceit"
    cidr                     = "10.1.0.0/16"
    azs                      = ["eu-west-1a", "eu-west-1b"]
    private_subnets          = ["10.1.0.0/20", "10.1.16.0/20"]
    public_subnets           = ["10.1.48.0/20", "10.1.64.0/20"]
    dhcp_options_domain_name = "faceit.fr"
  }


  eks = {
    name           = "eks-faceit"
    version        = "1.24"
    instance_types = ["t2.small"]
    desired_size   = 2
    asg_max_size   = 4
    disk_size      = 50
  }
  public_domain = "faceit.akira.fr"
  caa_records = [
    "0 issue \"amazontrust.com\"",
    "0 issue \"amazonaws.com\"",
    "0 issue \"awstrust.com\"",
    "0 issue \"amazon.com\"",
    "0 issue \"letsencrypt.org\"",
  ]
}
