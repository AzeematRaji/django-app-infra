# terraform.tfvars
aws_region = "us-east-1"  # Choose your preferred region

# Generate a UNIQUE bucket name (S3 buckets must be globally unique)
s3_bucket_name = "django-app-yourname-20241207-bucket"  # Make this unique!

# Database configuration  
db_name = "djangoapp"
db_username = "djangouser"
db_password = "YourSecurePassword123!"  # Change this!

# Instance configuration (start small)
instance_type = "t3.small"  # Cost-effective for testing
min_size = 1
max_size = 3
desired_capacity = 1

# Network (can keep defaults)
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Tags
common_tags = {
  Environment = "dev"
  Project     = "django-app"
  Owner       = "your-name"
  ManagedBy   = "terraform"
}

# terraform/terraform.tfvars.example
aws_region = "us-east-1"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Compute Configuration
instance_type = "t3.medium"
min_size = 2
max_size = 6
desired_capacity = 2

# Database Configuration
db_name = "djangoapp"
db_username = "djangouser"
db_password = "YourSecurePasswordHere123!"

# Storage Configuration
s3_bucket_name = "your-unique-django-app-bucket-name-2024"

# Tags
common_tags = {
  Environment = "production"
  Project     = "django-app"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
}