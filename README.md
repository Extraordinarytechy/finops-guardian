#  Satellite Project 2: FinOps Guardian

## Overview
**FinOps Guardian** is a complete, automated system for **cloud financial management (FinOps)**.  
It solves two key business problems:
1. Lack of visibility into **daily cloud spending**
2. Lack of control over **resource creation and tagging**

The system provides:
- **Automated cost reporting** (reactive control)
- **Proactive tag governance** (preventative control)

All components are **serverless** and deployed as **Infrastructure as Code (IaC)** using Terraform.

---

##  Key Features

### 1. Automated Cost Reporting
- A **daily Lambda function** (Python + boto3) scans AWS accounts.
- Groups costs by the `Environment` tag.
- Sends a concise **summary report** via **Amazon Simple Email Service (SES)**.
- Triggered automatically by a **CloudWatch Event** (cron at 12:00 UTC).

### 2. Proactive Tag Governance
- A **Service Control Policy (SCP)** enforces mandatory `Environment` tags.
- Prevents the creation of **untagged EC2 and RDS instances**.
- Ensures cost accountability and governance compliance.

---

##  Architecture

```

[CloudWatch Event] (Daily Cron: 12:00 UTC)
|
| Triggers
v
[IAM Role (Least Privilege)]
|
| Attached to
v
[Lambda Function (Python)]
|
| 1. Queries Cost Explorer (ce:GetCostAndUsage)
| 2. Formats Report
| 3. Sends Email via SES (ses:SendEmail)
v
[Stakeholder Email]

```

The architecture is **serverless**, **event-driven**, and designed for **zero maintenance**.

---

##  Technical Implementation

### Infrastructure as Code (IaC)
- All resources are managed using **Terraform**:
  - Lambda Function
  - IAM Role (least privilege)
  - EventBridge (CloudWatch) Scheduler
  - Optional SCP (for organizational enforcement)

### Lambda Function
- Written in **Python 3.9**
- Uses **boto3** to:
  - Query **Cost Explorer**
  - Send emails via **SES**
- Deployed via Terraform as a `.zip` package

### Security
- Lambda IAM role follows **least privilege**:
  - `ce:GetCostAndUsage`
  - `ses:SendEmail`
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

---

##  The Governance Policy (SCP)

The **Guardian** component ensures that all resources are properly tagged.

- **File:** `policy.json`  
  Contains a production-ready **Service Control Policy** denying:
  - `ec2:RunInstances`
  - `rds:CreateDBInstance`  
  …if the `Environment` tag is **missing**.

- **Terraform file:** `scp.tf`  
  Deploys this policy via Terraform.

> **Note:**  
> SCPs can only be applied in **AWS Organizations**.  
> Since this project runs in a standalone AWS account, the SCP resources are commented out to avoid deployment errors.  
> The simulation still demonstrates full governance and reporting workflows.

---

##  Project Structure

```

/2-FinOps-Guardian
├── /lambda
│   └── cost_reporter.py        # Core Python logic for Lambda
│
├── /terraform
│   ├── main.tf                 # Lambda, IAM Role, and EventBridge Trigger
│   ├── variables.tf            # Input variables
│   ├── scp.tf                  # (Simulated) Service Control Policy
│   ├── policy.json             # JSON definition of the SCP
│   └── terraform.tfvars        # (Not committed: stores email configs)
│
├── .gitignore
└── README.md

````

---

##  How to Deploy

### 1. Prerequisite
- Verify a **sender email address** in **Amazon SES** (region: `us-east-1`).

### 2. Configure
- Create a file `terraform.tfvars` inside the `/terraform` folder:

```hcl
sender_email    = "verified_sender@example.com"
recipient_email = "recipient@example.com"
````

### 3. Package the Lambda

```bash
cd lambda
zip cost_reporter.zip cost_reporter.py
cd ..
```

### 4. Deploy via Terraform

```bash
cd terraform
terraform init
terraform apply
```

Once deployed, the Lambda will automatically:

* Run daily (12:00 UTC)
* Email a summarized AWS cost report grouped by environment

---

##  Summary

| Category          | Component                | Description                        |
| ----------------- | ------------------------ | ---------------------------------- |
| **Compute**       | AWS Lambda               | Runs Python script for reporting   |
| **Governance**    | Service Control Policy   | Enforces tagging standards         |
| **Event Trigger** | CloudWatch (EventBridge) | Daily cron schedule                |
| **Notification**  | SES                      | Sends email reports                |
| **IaC**           | Terraform                | Complete infrastructure definition |

---

##  License

This project is released under the [MIT License](LICENSE).

---

##  Author

**Ajay** — Cloud & DevOps Engineer
Part of the *Satellite Project Series* focusing on **Serverless + FinOps Automation**.