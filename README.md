# AWS Three-Tier Web-app Architecture

## Overview
Deploys a secure and scalable three-tier web architecture on AWS with a public ALB, private EC2 instances, and a private RDS database inside a custom VPC.

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