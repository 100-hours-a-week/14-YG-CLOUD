# Terraform 가이드

## 디렉토리 구조

- envs/dev
- envs/test
- envs/prod
- modules/

## 사용법

- Dev: cd terraform/envs/dev && terraform init && terraform apply -var-file=terraform.tfvars
- Test: cd terraform/envs/test && terraform init && terraform apply -var-file=terraform.tfvars
- Prod: cd terraform/envs/prod && terraform init && terraform apply -var-file=terraform.tfvars
