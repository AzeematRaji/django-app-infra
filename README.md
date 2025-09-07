# AWS Django Application Infrastructure

This repository contains Infrastructure as Code (IaC) implementations for deploying a highly available, scalable Django application on AWS using both Terraform and CloudFormation.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Terraform Deployment](#terraform-deployment)
- [CloudFormation Deployment](#cloudformation-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Cleanup](#cleanup)

## Overview

This infrastructure solution deploys a production-ready Django application with the following features:

- **High Availability**: Multi-AZ deployment across 2+ availability zones
- **Auto Scaling**: Automatic scaling based on CPU utilization (2-6 instances)
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Database**: Multi-AZ PostgreSQL RDS with automated backups
- **Storage**: S3 bucket for static files and application logs
- **Monitoring**: CloudWatch dashboards, alarms, and log aggregation
- **Security**: VPC with public/private subnets, security groups, IAM roles

## Architecture

### Components

1. **VPC (10.0.0.0/16)** - Virtual Private Cloud with DNS resolution enabled
2. **Public Subnets (2)** - Host ALB and NAT Gateways
3. **Private Subnets (2)** - Host EC2 instances and RDS database
4. **Internet Gateway** - Provides internet access
5. **NAT Gateways (2)** - Outbound internet access for private subnets
6. **Application Load Balancer** - Distributes traffic across EC2 instances
7. **Auto Scaling Group** - Manages EC2 instances with health checks
8. **RDS PostgreSQL** - Multi-AZ database with automated backups
9. **S3 Bucket** - Static file storage with versioning and encryption
10. **CloudWatch** - Monitoring, logging, and alerting

### Network Flow

```
Internet → IGW → ALB → Private EC2 Instances → RDS Database
                 ↓
               S3 Bucket ← CloudWatch Logs
```

## Prerequisites

### Required Tools
- **AWS CLI** (v2.x) - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (≥ 1.0) - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **Git** - For cloning the repository

### AWS Account Requirements
- AWS account with appropriate permissions
- Configured AWS CLI credentials
- EC2 Key Pair (optional, for SSH access)

### Permissions Required
The following AWS permissions are needed:
- EC2: Full access for instances, VPC, security groups
- RDS: Full access for database management
- S3: Full access for bucket management
- IAM: Role and policy management
- CloudWatch: Metrics and logs management
- Auto Scaling: ASG and scaling policies
- Elastic Load Balancing: ALB management

## Quick Start

### Option 1: Automated Terraform Deployment

```bash
# Clone the repository
git clone <repository-url>
cd aws-infrastructure

# Make scripts executable
chmod +x *.sh

# Run automated deployment
./deploy-terraform.sh
```

### Option 2: Automated CloudFormation Deployment

```bash
# Clone the repository
git clone <repository-url>
cd aws-infrastructure

# Make scripts executable
chmod +x *.sh

# Run CloudFormation deployment
./deploy-cloudformation.sh
```

## Terraform Deployment

### Manual Step-by-Step Deployment

1. **Navigate to Terraform directory:**
   ```bash
   cd terraform/
   ```

2. **Create configuration file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars:**
   ```hcl
   aws_region = "us-east-1"
   
   # Database configuration
   db_password = "YourSecurePassword123!"
   
   # S3 bucket (must be globally unique)
   s3_bucket_name = "your-unique-bucket-name-2024"
   
   # Optional customizations
   instance_type = "t3.medium"
   min_size = 2
   max_size = 6
   desired_capacity = 2
   ```

4. **Deploy infrastructure:**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Review the plan
   terraform plan
   
   # Apply the configuration
   terraform apply
   ```

5. **Get application URL:**
   ```bash
   terraform output load_balancer_dns_name
   ```

### Terraform Module Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf           # Variable definitions
├── outputs.tf            # Output values
├── terraform.tfvars      # Variable values
└── modules/
    ├── vpc/              # VPC and networking
    ├── security/         # Security groups and IAM
    ├── compute/          # EC2, ASG, ALB
    ├── database/         # RDS configuration
    ├── storage/          # S3 bucket
    └── monitoring/       # CloudWatch resources
```

## CloudFormation Deployment

### Manual Deployment

1. **Deploy using AWS CLI:**
   ```bash
   aws cloudformation create-stack \
     --stack-name django-app-stack \
     --template-body file://cloudformation/django-app-stack.yaml \
     --parameters \
       ParameterKey=DBPassword,ParameterValue=YourSecurePassword123! \
       ParameterKey=S3BucketName,ParameterValue=your-unique-bucket-name \
     --capabilities CAPABILITY_IAM \
     --region us-east-1
   ```

2. **Monitor deployment:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name django-app-stack \
     --query 'Stacks[0].StackStatus'
   ```

3. **Get outputs:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name django-app-stack \
     --query 'Stacks[0].Outputs'
   ```

### CloudFormation Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| VpcCIDR | CIDR block for VPC | 10.0.0.0/16 | No |
| InstanceType | EC2 instance type | t3.medium | No |
| MinSize | Minimum instances | 2 | No |
| MaxSize | Maximum instances | 6 | No |
| DBPassword | Database password | - | Yes |
| S3BucketName | S3 bucket name | - | Yes |

## Monitoring and Maintenance

### CloudWatch Dashboard

The deployment creates a CloudWatch dashboard with the following metrics:
- Application Load Balancer metrics (requests, response time, error rates)
- EC2 Auto Scaling Group metrics (instance count, CPU utilization)
- RDS metrics (CPU, memory, connections, latency)

### Alarms and Auto Scaling

**Scale-Up Triggers:**
- CPU utilization > 75% for 10 minutes
- Adds 1 instance with 5-minute cooldown

**Scale-Down Triggers:**
- CPU utilization < 25% for 10 minutes
- Removes 1 instance with 5-minute cooldown

### Log Management

**Log Groups Created:**
- `/aws/ec2/django-app` - Application logs
- `/aws/ec2/django-app/access` - Nginx access logs

**Log Retention:**
- Application logs: 7 days
- Access logs: 30 days

### Health Checks

The application includes a health check endpoint at `/health/` that:
- Returns HTTP 200 status when healthy
- Used by ALB target group health checks
- Monitored by Auto Scaling Group

### Backup Strategy

**RDS Backups:**
- Automated daily backups with 7-day retention
- Backup window: 03:00-04:00 UTC
- Maintenance window: Sunday 04:00-05:00 UTC
- Multi-AZ for high availability

**S3 Versioning:**
- Enabled for static files and logs
- Cross-region replication can be added if needed

## Security

### Network Security

**VPC Configuration:**
- Private subnets for application and database tiers
- Public subnets only for load balancer and NAT gateways
- Security groups with least-privilege access

**Security Group Rules:**
- ALB: HTTP (80) and HTTPS (443) from internet
- EC2: Port 8000 from ALB security group only
- RDS: Port 5432 from EC2 security group only

### Identity and Access Management

**IAM Roles:**
- EC2 instances use dedicated IAM role
- Least-privilege permissions for S3 and CloudWatch
- No hardcoded credentials in application

**S3 Security:**
- Server-side encryption (AES-256)
- Public access blocked
- Bucket policy restricts access to EC2 role

### Data Protection

**Encryption:**
- RDS encryption at rest available (configure via parameter)
- S3 server-side encryption enabled
- EBS volumes can be encrypted (add to launch template)

**Access Controls:**
- Database access restricted to application tier
- S3 access restricted to application instances
- SSH access limited to VPC CIDR range

## Troubleshooting

### Common Issues

#### 1. Application Not Accessible

**Symptoms:** Cannot reach application via load balancer URL

**Troubleshooting Steps:**
```bash
# Check load balancer status
aws elbv2 describe-load-balancers --names django-app-alb

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names django-app-asg
```

**Common Causes:**
- Instances still launching (wait 5-10 minutes)
- Health check failures
- Security group misconfigurations

#### 2. Database Connection Issues

**Symptoms:** Application shows database connection errors

**Troubleshooting Steps:**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier django-app-db

# Check security groups
aws ec2 describe-security-groups --group-ids <db-security-group-id>

# Check environment variables on EC2
ssh into instance and check /etc/environment
```

#### 3. Auto Scaling Not Working

**Symptoms:** Instances not scaling up/down as expected

**Troubleshooting Steps:**
```bash
# Check scaling policies
aws autoscaling describe-policies --auto-scaling-group-name django-app-asg

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names django-app-high-cpu django-app-low-cpu

# Check scaling activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name django-app-asg
```

### Health Check Script

Use the provided health check script to monitor application status:

```bash
./health-check.sh
```

### Logs Analysis

**View application logs:**
```bash
aws logs describe-log-streams --log-group-name /aws/ec2/django-app
aws logs get-log-events --log-group-name /aws/ec2/django-app --log-stream-name <stream-name>
```

**Monitor real-time logs:**
```bash
aws logs tail /aws/ec2/django-app --follow
```

## Cost Optimization

### Resource Sizing Recommendations

**Development Environment:**
- Instance Type: t3.micro or t3.small
- RDS: db.t3.micro
- Min/Max Instances: 1/2

**Production Environment:**
- Instance Type: t3.medium or t3.large
- RDS: db.t3.small or db.t3.medium
- Min/Max Instances: 2/6

### Cost-Saving Features

1. **Auto Scaling:** Automatically adjusts capacity based on demand
2. **Spot Instances:** Can be configured for non-critical workloads
3. **Reserved Instances:** Consider for predictable workloads
4. **S3 Lifecycle Policies:** Transition logs to cheaper storage classes

### Monthly Cost Estimates (us-east-1)

**Basic Setup (2 t3.medium instances):**
- EC2 instances: ~$60/month
- ALB: ~$20/month
- RDS db.t3.micro: ~$15/month
- NAT Gateways: ~$45/month
- S3 and data transfer: ~$10/month
- **Total: ~$150/month**

**Note:** Costs vary based on usage, region, and specific configuration.

## Cleanup

### Terraform Cleanup

```bash
# Using the provided script
./destroy-infrastructure.sh

# Or manually
cd terraform/
terraform destroy
```

### CloudFormation Cleanup

```bash
# Using the provided script
./destroy-infrastructure.sh

# Or manually
aws cloudformation delete-stack --stack-name django-app-stack
```

### Manual Cleanup Verification

After running destroy commands, verify these resources are deleted:
- VPC and associated networking components
- EC2 instances and Auto Scaling Groups
- RDS database instances
- S3 buckets (may need manual deletion if not empty)
- IAM roles and policies
- CloudWatch log groups

## Advanced Configuration

### SSL/TLS Configuration

To add HTTPS support:

1. **Request SSL certificate:**
   ```bash
   aws acm request-certificate \
     --domain-name your-domain.com \
     --validation-method DNS
   ```

2. **Update ALB listener:**
   Add HTTPS listener (port 443) in Terraform or CloudFormation

3. **Update security groups:**
   Allow HTTPS traffic (port 443)

### Custom Domain Setup

1. **Route 53 hosted zone:**
   ```bash
   aws route53 create-hosted-zone --name your-domain.com --caller-reference $(date +%s)
   ```

2. **Create CNAME record:**
   Point your domain to the ALB DNS name

### Database Encryption

To enable RDS encryption at rest:

**Terraform:**
```hcl
resource "aws_db_instance" "main" {
  # ... other configurations
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
}
```

**CloudFormation:**
```yaml
Database:
  Type: AWS::RDS::DBInstance
  Properties:
    # ... other properties
    StorageEncrypted: true
```

### Multi-Region Deployment

For multi-region setup:
1. Deploy infrastructure in multiple regions
2. Configure Route 53 for DNS failover
3. Set up cross-region RDS read replicas
4. Consider S3 cross-region replication

## Support and Contributing

### Getting Help

1. **Check the troubleshooting section** for common issues
2. **Review AWS CloudWatch logs** for detailed error information
3. **Use the health check script** to diagnose problems
4. **Check AWS service status** at [AWS Service Health Dashboard](https://status.aws.amazon.com/)

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Best Practices

1. **Always test in a development environment first**
2. **Use version control for infrastructure code**
3. **Regularly update AMIs and dependencies**
4. **Monitor costs and set up billing alerts**
5. **Follow AWS Well-Architected Framework principles**
6. **Implement proper backup and disaster recovery procedures**
7. **Regularly review and update security configurations**

---

## License

This infrastructure code is provided under the MIT License. See LICENSE file for details.

## Disclaimer

This infrastructure template is provided as-is for educational and development purposes. For production use, please review and customize the configuration according to your security, compliance, and operational requirements.