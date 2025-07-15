# 🚨 Terraform State 불일치 트러블슈팅

> **발생 시점**: 2025년 7월 15일  
> **상황**: Dev 환경 terraform 구성을 다른 repository 위치로 이전 중 state 불일치 발생

## 📋 문제 상황

### 초기 문제
- **목표**: 기존 GitHub path (`/Users/lsh/Documents/GitHub/14-YG-CLOUD/`)의 dev terraform을 현재 위치로 이전
- **기대결과**: `terraform plan` 실행 시 "No changes" 출력
- **실제결과**: 새로운 리소스 생성 및 기존 리소스 변경 시도

### 문제 증상
```bash
# 현재 위치에서 실행
$ terraform plan
Plan: 1 to add, 1 to change, 0 to destroy.

# 기존 GitHub 위치에서 실행  
$ terraform plan
No changes. Your infrastructure matches the configuration.
```

### 근본 원인
1. **Backend 설정 차이**: GCS backend vs Local backend
2. **State 파일 위치**: 서로 다른 state 참조
3. **Provider 버전 차이**: 다른 google provider 버전
4. **Output 구성 차이**: `prod_vm_ip` vs `dev_vm_ip` 불일치

## 🔍 분석 과정

### 1단계: State 위치 확인
```bash
# GCS backend에 state 존재 확인
$ gsutil ls gs://ktb-2-moongsan-terraform-state/environments/dev/
gs://ktb-2-moongsan-terraform-state/environments/dev/default.tfstate

# State 내용 확인
$ gsutil cat gs://ktb-2-moongsan-terraform-state/environments/dev/default.tfstate | jq '.resources[].name'
"static_ip"
"vm"
```

### 2단계: 구성 파일 차이 분석
```bash
# 기존 위치의 terraform output
$ cd /Users/lsh/Documents/GitHub/14-YG-CLOUD/terraform && terraform output
prod_vm_ip = "34.64.59.25"

# 현재 위치의 terraform plan 결과
Plan: 1 to add, 1 to change, 0 to destroy.
- google_compute_firewall.allow-web-traffic will be created
- google_compute_instance.vm will be updated (labels change)
```

### 3단계: 리소스 상태 확인
```bash
# 실제 GCP 리소스 확인
$ gcloud compute instances list --filter="name:moongsan-dev"
NAME             ZONE               MACHINE_TYPE  EXTERNAL_IP
moongsan-dev-vm  asia-northeast3-a  e2-highmem-2  34.64.59.25

$ gcloud compute firewall-rules list --filter="name:dev"
NAME                   NETWORK  PRIORITY  ALLOW
dev-allow-web-traffic  default  1000      tcp:22,tcp:80,tcp:443...
```

## ✅ 해결 과정

### 해결책 1: 전체 구성 복사 (성공)
```bash
# 현재 dev 디렉토리 제거
$ rm -rf terraform/environments/dev

# 새로 생성
$ mkdir -p terraform/environments/dev

# 기존 구성 전체 복사 (state 파일 포함)
$ cp -r /Users/lsh/Documents/GitHub/14-YG-CLOUD/terraform/* terraform/environments/dev/

# 재초기화
$ cd terraform/environments/dev
$ terraform init
$ terraform plan
No changes. Your infrastructure matches the configuration.
```

### 해결책 검증
```bash
# Output 확인
$ terraform output
prod_vm_ip = "34.64.59.25"  # ✅ 정상

# State 리소스 확인
$ terraform state list
google_compute_address.static_ip
google_compute_firewall.allow-web-traffic  
google_compute_instance.vm
```

## 📝 학습 내용

### 핵심 교훈
1. **State 무결성**: Terraform state는 구성과 완벽히 매칭되어야 함
2. **Backend 일관성**: 같은 인프라는 같은 backend를 사용해야 함
3. **전체 복사의 효과**: 부분 복사보다 전체 구성 복사가 안전함
4. **Provider 버전**: 같은 provider 버전 사용이 중요함

### 향후 예방책
1. **Backend 설정 통일**: 모든 환경에서 동일한 backend 구조 사용
2. **State 백업**: 중요한 변경 전 state 백업 수행
3. **단계별 검증**: 각 단계마다 `terraform plan`으로 검증
4. **문서화**: 이런 문제 상황과 해결책 문서로 기록

### 다음 단계 작업
1. **Output 수정**: `prod_vm_ip` → `dev_vm_ip`로 변경
2. **Ansible 연동**: Dev terraform output을 ansible inventory에서 사용
3. **Backend 설정**: GCS backend 적용 (현재는 local state 사용 중)
4. **테스트**: 실제 배포 테스트로 구성 검증

## 🎯 현재 상태

- ✅ **Terraform State**: 정상 (No changes)
- ✅ **리소스 인식**: 기존 인프라 정상 인식
- 🔄 **Output 수정**: `prod_vm_ip` → `dev_vm_ip` 필요
- 🔄 **Ansible 연동**: Dev inventory 설정 필요
- 🔄 **Backend 적용**: GCS backend 설정 예정

---

📝 **작성일**: 2025년 7월 15일  
🔍 **문제 해결 시간**: 약 30분  
✅ **해결 상태**: 완료 (후속 작업 남음)
