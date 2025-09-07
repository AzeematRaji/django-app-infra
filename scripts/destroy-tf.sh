#!/bin/bash

set -e

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

# Function to destroy Terraform infrastructure
destroy_terraform() {
    print_status "Destroying Terraform infrastructure..."
    
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No Terraform state found."
        return
    fi
    
    terraform init
    terraform destroy -auto-approve
    
    print_status "Terraform infrastructure destroyed!"
}

main() {
    print_warning "This will destroy ALL infrastructure resources!"
    print_warning "This action cannot be undone."
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_status "Operation cancelled."
        exit 0
    fi
    
    # Check which deployment method was used
    if [ -f "terraform.tfstate" ]; then
        destroy_terraform
    fi
    
    if aws cloudformation describe-stacks --stack-name "django-app-stack" &> /dev/null; then
        destroy_cloudformation
    fi
    
    print_status "Cleanup completed!"
}
main "$@"