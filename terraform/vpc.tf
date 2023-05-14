module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = local.vpc.name

  cidr            = local.vpc.cidr
  azs             = local.vpc.azs
  private_subnets = local.vpc.private_subnets
  public_subnets  = local.vpc.public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = false
  enable_nat_gateway   = true

  # ACLs
  manage_default_network_acl = true
  default_network_acl_tags = {
    Name = "Default route table"
  }
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true

  # DHCP Options
  enable_dhcp_options              = true
  dhcp_options_domain_name         = local.vpc.dhcp_options_domain_name
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # VPC Flow Logs
  enable_flow_log = false

  enable_vpn_gateway = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks.name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks.name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# Private DNS zone (in VPC)
resource "aws_route53_zone" "private" {
  name    = local.vpc.dhcp_options_domain_name
  comment = "${module.vpc.name} VPC zone"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_zone" "public" {
  name    = local.public_domain
  comment = "Public ${local.public_domain} zone"
}

resource "aws_route53_record" "caa" {
  zone_id = aws_route53_zone.public.zone_id
  name    = local.public_domain
  type    = "CAA"
  ttl     = 3600
  records = local.caa_records
}
