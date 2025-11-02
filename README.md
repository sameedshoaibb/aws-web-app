# AWS WebApp architecture

## Application Demo
<img width="1352" height="869" alt="Screenshot 2025-11-02 at 8 15 51 PM" src="https://github.com/user-attachments/assets/99f97164-bcf4-4c22-a3af-d4338924d648" />

## Overview
This project deploys a secure and scalable three-tier architecture on AWS, featuring a public Application Load Balancer (ALB), private EC2 instances, and a private RDS database, all within a custom VPC designed for high availability and security.

It demonstrates core AWS best practices, including network segmentation, least-privilege security, auto scaling, and encrypted traffic flows between application tiers.

## What It Deploys
- Public ALB routing to private EC2 app instances  
- Private RDS database in isolated subnets  
- VPC with public/private subnets, IGW, NAT, and route tables  

## Core Components
- **Networking:** VPC, subnets, IGW, NAT, route tables  
- **Compute:** Auto Scaling Group with Launch Template (EC2 in private subnets)  
- **Load Balancing:** ALB + Target Group + health checks  
- **Database:** Amazon RDS in private subnets (DB Subnet Group)  
- **Security:** SGs (ALB → EC2 → RDS), least-privilege IAM  
- **Secrets:** AWS Secrets Manager or SSM  
- **Monitoring:** CloudWatch metrics/logs, optional ALB logs to S3  

## Traffic Flow
Internet → ALB (public) → EC2 (private) → RDS (private)

## Security Highlights
- No public IPs on EC2 or RDS  
- Tight SG rules between tiers  

## Deployment Workflow
```bash 
- git clone <repo_url>
- cd <repo>
- terraform init
- terraform plan
- terraform apply
