locals {
  ami_type               = "AL2_x86_64"
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  capacity_type          = "SPOT"
  cluster_name           = "course-project"
  cluster_version        = "1.25"
  disk_size              = 30
  enable_cluster_creator = true
  enable_nat_gateway     = true
  enable_public_access   = true
  instance_types         = ["t2.micro"]
  node_desired_size      = 1
  node_max_size          = 3
  node_min_size          = 1
  intra_subnets          = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets         = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  single_nat_gateway     = true
  vpc_cidr               = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "5.6.0"
  name               = "${local.cluster_name}-vpc" # microservice-course-project-vpc
  azs                = local.azs
  cidr               = local.vpc_cidr
  intra_subnets      = local.intra_subnets
  private_subnets    = local.private_subnets
  public_subnets     = local.public_subnets
  enable_nat_gateway = local.enable_nat_gateway
  single_nat_gateway = local.single_nat_gateway
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.8.3"
  control_plane_subnet_ids                 = module.vpc.intra_subnets
  cluster_name                             = local.cluster_name
  cluster_version                          = local.cluster_version
  cluster_endpoint_public_access           = local.enable_public_access
  enable_cluster_creator_admin_permissions = local.enable_cluster_creator
  subnet_ids                               = module.vpc.private_subnets
  vpc_id                                   = module.vpc.vpc_id

  eks_managed_node_groups = {
    course-project = {
      ami_type       = local.ami_type
      capacity_type  = local.capacity_type
      disk_size      = local.disk_size
      desired_size   = local.node_desired_size
      instance_types = local.instance_types

      launch_template_tags = {
        Name = "${local.cluster_name}-node"
      }

      max_size = local.node_max_size
      min_size = local.node_min_size
    }
  }
}

resource "aws_eks_addon" "vpc_cni" {
  addon_name = "vpc-cni"
  cluster_name = module.eks.cluster_name
}