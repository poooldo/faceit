module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name                         = local.eks.name
  cluster_version                      = local.eks.version
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access       = true

  cluster_ip_family          = "ipv4"
  create_cni_ipv6_iam_policy = false

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_ipv4_irsa_role.iam_role_arn
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  enable_irsa                                = true
  create_iam_role                            = true
  create_cluster_security_group              = true
  create_cluster_primary_security_group_tags = false
  create_cloudwatch_log_group                = false
  cluster_enabled_log_types                  = []
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64"
    attach_cluster_primary_security_group = true

    iam_role_attach_cni_policy = true

    instance_types    = local.eks.instance_types
    capacity_type     = "ON_DEMAND"
    min_size          = local.eks.desired_size
    max_size          = local.eks.asg_max_size
    desired_size      = local.eks.desired_size
    enable_monitoring = false
    update_config = {
      max_unavailable = 1
    }

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = local.eks.disk_size
          volume_type           = "gp3"
          encrypted             = false
          delete_on_termination = true
        }
      }
    }

    tags = {
      "k8s.io/cluster-autoscaler/${local.eks.name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"                                = "true"
    }
  }

  eks_managed_node_groups = {
    for index, az in module.vpc.azs : az => {
      subnet_ids = [module.vpc.private_subnets[index]]
    }
  }
}

module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5"

  role_name                        = "${local.eks.name}-cluster-autoscaler-irsa"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5"

  role_name             = "${local.eks.name}-ebs-csi-irsa"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "vpc_cni_ipv4_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5"

  role_name             = "${local.eks.name}-vpc-cni-ipv4-irsa"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
