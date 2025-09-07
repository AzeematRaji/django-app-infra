#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
STACK_NAME="django-app-stack"
TEMPLATE_FILE="cloudformation/django-app-stack.yaml"

# Function to generate unique bucket name
generate_bucket_name() {
    local timestamp=$(date +%Y%m%d%H%M%S)
    local random=$(openssl rand -hex 4)
    echo "django-app-cf-${timestamp}-${random}"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured."
        exit 1
    fi
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "CloudFormation template not found: $TEMPLATE_FILE"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Get user inputs
get_inputs() {
    print_status "Getting deployment parameters..."
    
    # Generate unique bucket name
    BUCKET_NAME=$(generate_bucket_name)
    print_status "Generated S3 bucket name: $BUCKET_NAME"
    
    # Get database password
    echo -n "Enter database password (min 8 characters): "
    read -s DB_PASSWORD
    echo ""
    
    if [ ${#DB_PASSWORD} -lt 8 ]; then
        print_error "Password must be at least 8 characters long."
        exit 1
    fi
}

# Deploy CloudFormation stack
deploy_stack() {
    print_status "Deploying CloudFormation stack: $STACK_NAME"
    
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=DBPassword,ParameterValue="$DB_PASSWORD" \
            ParameterKey=S3BucketName,ParameterValue="$BUCKET_NAME" \
        --capabilities CAPABILITY_IAM \
        --tags \
            Key=Environment,Value=production \
            Key=Project,Value=django-app \
            Key=ManagedBy,Value=cloudformation
    
    print_status "Stack creation initiated. Waiting for completion..."
    
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"
    
    if [ $? -eq 0 ]; then
        print_status "Stack created successfully!"
    else
        print_error "Stack creation failed!"
        exit 1
    fi
}

# Get stack outputs
get_outputs() {
    print_status "Getting stack outputs..."
    
    local lb_url=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
        --output text)
    
    local vpc_id=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' \
        --output text)
    
    echo ""
    echo "=========================================="
    echo "           DEPLOYMENT COMPLETE"
    echo "=========================================="
    echo "Application URL: $lb_url"
    echo "S3 Bucket: $BUCKET_NAME"
    echo "VPC ID: $vpc_id"
    echo ""
    echo "It may take 5-10 minutes for the application"
    echo "to be fully available after deployment."
    echo "=========================================="
}

# Main execution
main() {
    print_status "Starting Django App CloudFormation Deployment"
    
    check_prerequisites
    get_inputs
    deploy_stack
    get_outputs
    
    print_status "Deployment completed successfully!"
}

main "$@"