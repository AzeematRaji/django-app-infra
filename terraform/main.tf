# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = var.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  vpc_id         = module.vpc.vpc_id
  s3_bucket_name = var.s3_bucket_name
  tags           = var.common_tags
}

# Database Module
module "rds" {
  source = "./modules/rds"
  
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_security_group_id  = module.iam.db_security_group_id
  
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  tags = var.common_tags
}

# Storage Module
module "s3" {
  source = "./modules/s3"
  
  bucket_name   = var.s3_bucket_name
  ec2_role_arn  = module.iam.ec2_role_arn
  tags          = var.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  ec2_security_group_id     = module.security.ec2_security_group_id
  ec2_instance_profile_name = module.security.ec2_instance_profile_name
  
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  
  rds_endpoint              = module.database.rds_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  s3_bucket_name           = module.storage.bucket_name
  
  tags = var.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  auto_scaling_group_name  = module.compute.auto_scaling_group_name
  load_balancer_arn_suffix = module.compute.load_balancer_arn_suffix
  rds_instance_id         = module.database.rds_instance_id
  scale_up_policy_arn     = module.compute.scale_up_policy_arn
  scale_down_policy_arn   = module.compute.scale_down_policy_arn
  
  tags = var.common_tags
}

