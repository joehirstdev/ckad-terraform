# CKAD Learning Environment

Terraform config for a 2-node Kubernetes cluster on GCP for CKAD practice.

Nodes are initialised with the CKAD learning materials available
(LF credentials required).

## Quick Start

```bash
# 1. Setup
cp terraform.tfvars.example terraform.tfvars
# Edit with your GCP project and LF Training credentials

# 2. Deploy
terraform init && terraform apply

# 3. SSH to nodes (IPs shown in output)
ssh -i ~/.ssh/id_rsa student@<CP_NODE_IP>
ssh -i ~/.ssh/id_rsa student@<WORKER_NODE_IP>

# 4. You will find lab materials ready at: ~/LFD259
```

## What You Get

- Control plane + worker node
- CKAD lab files pre-downloaded
- Kubernetes-ready networking
- Ready for CKAD certification practice

## Requirements

- GCP project with billing
- Terraform + gcloud CLI
- SSH keys (`~/.ssh/id_rsa.pub`)
- LF Training credentials

**⚠️ Run `terraform destroy` when done to avoid charges**
