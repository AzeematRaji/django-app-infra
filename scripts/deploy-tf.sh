#!/bin/bash
# deploy-terraform.sh - Automated Terraform deployment script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Generate unique S3 bucket name
generate_bucket_name() {
    local timestamp=$(date +%Y%m%d%H%M%S)
    local random=$(openssl rand -hex 4)
    echo "django-app-bucket-${timestamp}-${random}"
}

# Create terraform.tfvars if it doesn't exist
setup_terraform_vars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_status "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Generate unique bucket name
        local bucket_name=$(generate_bucket_name)
        sed -i.bak "s/your-unique-django-app-bucket-name-2024/${bucket_name}/g" terraform.tfvars
        
        print_warning "Please edit terraform.tfvars and set your database password!"
        print_warning "Current bucket name: ${bucket_name}"
        
        read -p "Press Enter to continue after updating terraform.tfvars..."
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    print_status "Applying Terraform plan..."
    terraform apply tfplan
    
    print_status "Deployment completed successfully!"
}

# Get deployment outputs
get_outputs() {
    print_status "Getting deployment outputs..."
    
    local lb_dns=$(terraform output -raw load_balancer_dns_name)
    local rds_endpoint=$(terraform output rds_endpoint)
    local s3_bucket=$(terraform output -raw s3_bucket_name)
    
    echo ""
    echo "=========================================="
    echo "           DEPLOYMENT COMPLETE"
    echo "=========================================="
    echo "Application URL: http://${lb_dns}"
    echo "S3 Bucket: ${s3_bucket}"
    echo "RDS Endpoint: ${rds_endpoint}"
    echo ""
    echo "It may take 5-10 minutes for the application"
    echo "to be fully available after deployment."
    echo "=========================================="
}

# Cleanup function
cleanup() {
    rm -f tfplan
}

# Main execution
main() {
    print_status "Starting Django App Infrastructure Deployment"
    
    check_prerequisites
    setup_terraform_vars
    deploy_infrastructure
    get_outputs
    cleanup
    
    print_status "Deployment script completed!"
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"