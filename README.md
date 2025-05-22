# multi-region-dr-aws
AWS Multi-Region Disaster Recovery with Terraform &amp; Jenkins
📖 Project Description
This project demonstrates how to set up a multi-region disaster recovery (DR) architecture on AWS using Terraform and Jenkins for CI/CD automation. The infrastructure is deployed in two AWS regions (us-east-1 and us-west-2) and includes VPCs, S3 buckets with cross-region replication, RDS databases with replication, Route 53 DNS failover, and automated deployment via Jenkins.

🗂️ Folder Structure
multi-region-dr-aws/
│
├── cicd/
│   └── Jenkinsfile         # Jenkins pipeline for CI/CD automation
│
└── terraform/
    ├── ec2.tf              # EC2 and Load Balancer resources
    ├── main.tf             # Main entry point, includes all modules
    ├── provider.tf         # AWS provider configuration for both regions
    ├── rds.tf              # RDS and replication resources
    ├── route53.tf          # Route 53 failover setup
    ├── s3.tf               # S3 buckets and cross-region replication
    ├── variables.tf        # Input variables
    └── vpc.tf              # VPC, subnets, gateways, and peering

🚀 End-to-End Flow
Networking:
Creates VPCs, subnets, routing, and gateways in two AWS regions.

Data Replication:
S3 buckets and RDS databases are set up for cross-region replication.

Failover:
Route 53 is configured for DNS failover, so if the primary region fails, traffic is routed to the backup region.

CI/CD Automation:
Jenkins pipeline automates infrastructure provisioning and updates.

Monitoring (optional):
CloudWatch can be integrated for monitoring replication and failover events.

🔒 Backend State Configuration (S3 & DynamoDB)
Terraform needs a backend to store its state file securely and to prevent conflicts during team changes.

Manual Setup Steps:
1. Create S3 Bucket for State:
aws s3api create-bucket --bucket terraform-state-multi-region-dr --region us-east-1

2. Create DynamoDB Table for Locking:
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

3. Why S3 and DynamoDB?
S3 stores the Terraform state file centrally and securely.
DynamoDB prevents simultaneous changes (locking), avoiding state corruption.

⚙️ How to Deploy
1. Clone the Repository:
git clone https://github.com/HeenaDania/multi-region-dr-aws.git
cd multi-region-dr-aws
2. Configure AWS Credentials:
Make sure your AWS CLI is configured with credentials that have permissions to create the required resources.
3. Set Sensitive Variables Securely:
Create a file terraform/terraform.tfvars (add to .gitignore!) and add:
db_password = "YourStrongPassword"
Or set as environment variable:
export TF_VAR_db_password="YourStrongPassword"
4. Initialize Terraform:
cd terraform
terraform init
5. Plan and Apply:
terraform plan
terraform apply
Or use the Jenkins pipeline for automated deployment.

🧪 Testing & Validation
No Domain Yet?
Use the outputted AWS Load Balancer DNS names to access your app:
http://<primary-alb-dns>
http://<secondary-alb-dns>
Simulate Failover:
Stop the EC2 instances in the primary region and check if traffic is routed to the secondary region’s ALB.

Check Replication:
Upload files to the primary S3 bucket and verify they appear in the secondary bucket.

📋 Notes & Recommendations
Do not commit secrets (like passwords) to the repository.

VPC peering is included for private cross-region networking, but S3 and RDS replication do not require it.

Route 53 failover works best with a real domain, but you can test using ALB DNS names.

Backend resources (S3/DynamoDB) must be created manually before first terraform init.

📚 References
AWS Multi-Region Disaster Recovery Guide

Terraform AWS Provider Docs

Jenkins Pipeline Documentation

🎥 Video Tutorials
AWS Route 53 Failover Routing

Terraform for Multi-Region Setup

CI/CD Pipeline with Jenkins and AWS

Happy deploying! For any issues, open an issue or reach out to the project maintainer.