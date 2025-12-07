# 🏛️ AWS EKS Modular Infrastructure (Reference Architecture)

![Terraform](https://img.shields.io/badge/Terraform-1.9-purple?style=flat&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS-orange?style=flat&logo=amazon-aws)
![CI/CD](https://img.shields.io/badge/GitHub_Actions-OIDC-blue?style=flat&logo=github-actions)
![Status](https://img.shields.io/badge/Status-Reference_Architecture-grey)

A comprehensive **Infrastructure as Code (IaC)** library designed to provision production-ready **Amazon EKS** clusters.

This repository serves as a catalog of advanced Terraform patterns for AWS, focusing on **modularity**, **security (Zero Trust)**, and **cost optimization**. It demonstrates a fully automated lifecycle for Kubernetes clusters, database layers, and networking.

---

## 🏗️ Architecture Design

The solution implements a scalable 3-tier architecture following the **AWS Well-Architected Framework**.

![AWS Architecture](./assets/architecture-diagram-aws.png)

---

### 🧩 Key Design Patterns

* **Network Isolation:** Multi-AZ VPC design with strictly separated Public (Ingress/NAT) and Private (Workloads/Data) subnets.
* **Identity Federation:** GitHub Actions authentication via **OIDC (OpenID Connect)**, eliminating long-lived AWS Access Keys.
* **Least Privilege:** Implementation of **IRSA (IAM Roles for Service Accounts)** to grant granular AWS permissions to specific Kubernetes Pods, not Nodes.
* **Cost Efficiency:** Usage of **Spot Instances** for stateless node groups and configurable NAT Gateways.

---

## 🚀 Infrastructure Capabilities

### 1. Networking & Security
* **VPC Module:** Dynamic subnets calculation, Route Tables, Internet Gateways, and single-NAT option for dev environments.
* **Security Groups:** Strict inbound/outbound rules following the principle of least privilege.
* **Encryption:** S3 buckets with SSE-S3/KMS and RDS encryption at rest.

### 2. Compute (Amazon EKS)
* **Control Plane:** Managed Kubernetes with public/private endpoint access control.
* **Data Plane:** Managed Node Groups supporting **Spot Instances** (for cost savings) and On-Demand instances (for critical workloads).
* **Add-ons Management:** Automated lifecycle for `vpc-cni`, `coredns`, and `kube-proxy`.

### 3. Data Persistence
* **Database:** Amazon RDS (PostgreSQL) deployed in private subnets.
* **Secret Management:** Database credentials automatically generated and stored in **AWS Secrets Manager**, avoiding plaintext passwords in state files.
* **Object Storage:** S3 buckets with versioning and lifecycle policies for application artifacts.

### 4. CI/CD Integration
* **Container Registry:** ECR repositories with immutable image tags and scan-on-push enabled.
* **Automation:** GitHub Actions workflows configured to Plan (on PR) and Apply (on Merge) infrastructure changes securely.

---

## 🛠️ Technology Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **IaC** | **Terraform** | Modular provisioning of all AWS resources. |
| **State** | **S3 + DynamoDB** | Remote backend with state locking and encryption. |
| **Compute** | **Amazon EKS** | Kubernetes 1.31+ with Managed Node Groups. |
| **Database** | **Amazon RDS** | PostgreSQL engine 15.x. |
| **Identity** | **AWS IAM** | OIDC Providers, Roles, and Policies. |
| **CI/CD** | **GitHub Actions** | Automated pipelines for Infra and App deployment. |


---

## 📂 Repository Structure

The project follows a modular structure to separate resource definitions from environment configurations.

```bash
.
├── bootstrap/             # S3 Backend & DynamoDB Lock setup
├── environments/
│   └── dev/               # Development environment instantiation
│       ├── main.tf        # Entry point (VPC, EKS, RDS composition)
│       ├── providers.tf   # AWS Provider config
│       └── variables.tf   # Environment-specific inputs
├── modules/               # Reusable Terraform Modules
│   ├── vpc/               # Network topology definition
│   ├── eks/               # Kubernetes Control Plane & Nodes
│   ├── iam-oidc-github/   # CI/CD Authentication logic
│   ├── ecr/               # Docker Registry configuration
│   └── rds-postgres/      # Database abstraction
└── .github/workflows/     # CI/CD Pipelines (Plan/Apply)
```

---

## ⚠️ Reference Architecture Notice

**This repository serves as a Reference Architecture and Pattern Library.**

The code provided here represents a sanitized version of a live environment. It is intended for educational purposes, architectural review, and as a foundation for new projects.
* **State:** The Terraform state backend configuration refers to resources that may have been decommissioned.
* **Variables:** Sensitive values (Account IDs, ARNs) have been replaced with placeholders or dynamic data sources.

---

## 👤 Author

**Justino Boggio**
*Devops Engineer | Cloud Engineer | SRE | Information Systems Engineer*

[LinkedIn](https://www.linkedin.com/in/justino-boggio-75a932204) | [GitHub](https://github.com/JustinoBoggio)