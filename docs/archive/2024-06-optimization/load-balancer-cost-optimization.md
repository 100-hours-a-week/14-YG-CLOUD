# 🚦 Load Balancer 추가 + 비용 최적화 조정 방안

## 🎯 **목표**
- Load Balancer 추가로 적절한 3-tier 아키텍처 구현
- 총 비용을 기존 예산($278/월) 이하로 유지
- 성능과 안정성 보장

## 📊 **현재 상황 분석**

### 현재 최적화된 비용:
```bash
Jump Box:  $13.84/월 (e2-small + 20GB)
Backend:   $53.63/월 (e2-standard-2 + 30GB)
AI:        $67.50/월 (e2-highmem-2 + 40GB)
Database:  $65.53/월 (e2-standard-2 + 100GB)
네트워킹:   $8.50/월
기타:      $0.69/월
─────────────────────
현재 총합: $209.69/월
```

### Load Balancer 추가 시:
```bash
HTTP(S) Load Balancer: $18.00/월
Health Checks (2개):   $1.00/월
SSL Certificate:       $0.00/월 (Google Managed)
─────────────────────
LB 추가 비용: $19.00/월

새로운 총합: $228.69/월
여유 예산: $49.31/월 ($278 - $228.69)
```

## 🔧 **추가 최적화 방안**

### **옵션 1: AI 서버 다운그레이드 (권장)**
```bash
현재: e2-highmem-2 (2 vCPU, 16GB) → $60.70/월
변경: e2-standard-2 (2 vCPU, 8GB)  → $48.53/월
절약: $12.17/월

AI 서버 총 비용: $48.53 + $6.80 = $55.33/월 (-$12.17)
```

**AI 서버 8GB로 충분한 이유:**
- 대부분의 AI 모델은 8GB로 실행 가능
- 필요시 스왑 메모리 활용
- 초기 단계에서는 충분한 스펙

### **옵션 2: Backend 디스크 추가 최적화**
```bash
현재: 30GB → $5.10/월
변경: 25GB → $4.25/월
절약: $0.85/월
```

### **옵션 3: AI 디스크 추가 최적화**
```bash
현재: 40GB → $6.80/월
변경: 35GB → $5.95/월
절약: $0.85/월
```

## 🎯 **최종 권장 구성**

### **조정된 VM 스펙:**
```hcl
# Jump Box (유지)
machine_type = "e2-small"
disk_size    = 20

# Backend (디스크 소폭 감소)
machine_type = "e2-standard-2"
disk_size    = 25

# AI (메모리 다운그레이드 + 디스크 감소)
machine_type = "e2-standard-2"  # e2-highmem-2 → e2-standard-2
disk_size    = 35

# Database (유지 - 안정성 중요)
machine_type = "e2-standard-2"
disk_size    = 100
```

### **최종 비용 계산:**
```bash
📦 Compute Resources:
Jump Box:  $13.84/월 (e2-small + 20GB)
Backend:   $52.78/월 (e2-standard-2 + 25GB)
AI:        $55.33/월 (e2-standard-2 + 35GB) ⭐ -$12.17
Database:  $65.53/월 (e2-standard-2 + 100GB)
소계:      $187.48/월

🌐 Networking:
Static IP: $7.30/월
Data Transfer: $1.20/월
소계: $8.50/월

🚦 Load Balancer:
HTTP(S) LB: $18.00/월
Health Checks: $1.00/월
소계: $19.00/월

☁️ Storage & Services:
GCS + KMS: $0.69/월

🎯 총 월간 비용: $215.67/월
원래 예산 대비: -$62.33/월 (22% 절약!)
LB 없는 구성 대비: +$6.98/월 (3% 증가)
```

## 📈 **성능 영향 분석**

### ✅ **AI 서버 메모리 다운그레이드 (16GB → 8GB)**

#### 충분한 이유:
```bash
일반적인 AI 워크로드:
- FastAPI + 모델 로딩: ~2-3GB
- 텍스트 생성 모델: ~1-4GB
- 이미지 처리 모델: ~2-6GB
- 운영체제 + 기타: ~1GB

총 사용량: ~6-8GB (8GB 내에서 충분)
```

#### 리스크 완화:
```bash
# 메모리 스왑 설정 (필요시)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Docker 메모리 제한
docker run --memory="6g" your-ai-container
```

#### 확장 계획:
```bash
모니터링 후 필요시:
e2-standard-2 → e2-highmem-2 (원클릭 업그레이드)
추가 비용: +$12.17/월
```

### ✅ **디스크 소폭 감소**
```bash
Backend: 30GB → 25GB (Spring Boot + 로그는 25GB로 충분)
AI: 40GB → 35GB (AI 모델 + 캐시용으로 적정)

실제 사용량 예상:
- Backend: ~15-20GB
- AI: ~25-30GB
```

## 🛠️ **구현 방안**

### **1단계: VM 스펙 조정**
```hcl
# terraform/environments/test/main.tf

# AI VM 스펙 조정
module "ai" {
  source = "../../modules/compute"

  project_name        = var.project_name
  env                 = var.env
  vm_name             = "ai"
  vm_role             = "ai"
  tier                = "app"
  machine_type        = "e2-standard-2"    # 변경: e2-highmem-2 → e2-standard-2
  disk_size           = 35                 # 변경: 40GB → 35GB
  zone                = var.zone
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  assign_external_ip  = false
  network_tags        = ["internal"]
  ssh_public_key_path = var.ssh_public_key_path
}

# Backend VM 디스크 미세 조정
module "backend" {
  # ...기존 설정...
  disk_size = 25  # 변경: 30GB → 25GB
}
```

### **2단계: Load Balancer 모듈 생성**
```bash
mkdir -p terraform/modules/load_balancer
```

### **3단계: 최적화된 LB 설정**
```hcl
# terraform/modules/load_balancer/main.tf
# 기본 HTTP(S) Load Balancer (고가용성 미사용)
resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_name}-${var.env}-lb-ip"
}

# Backend 서비스 (최소 설정)
resource "google_compute_backend_service" "backend" {
  name                  = "${var.project_name}-${var.env}-backend"
  load_balancing_scheme = "EXTERNAL"
  
  backend {
    group = var.backend_instance_group
  }
  
  health_checks = [google_compute_health_check.backend.id]
  
  # 비용 최적화: 기본 설정 사용
  session_affinity = "NONE"
  timeout_sec      = 30
}
```

## 📊 **최적화 효과 요약**

### **AI 서버 다운그레이드 효과:**
```bash
메모리: 16GB → 8GB
비용 절약: $12.17/월
성능 영향: 최소 (8GB로 충분)
확장성: 언제든 업그레이드 가능
```

### **전체 비용 비교:**
```bash
원래 계획 (LB 없음): $278.00/월
현재 최적화: $209.69/월
LB + 추가 최적화: $215.67/월

최종 절약액: $62.33/월 (22% 절약!)
```

### **아키텍처 개선:**
```bash
✅ 적절한 3-tier 구조
✅ 일반 사용자 접근 가능
✅ SSL 종료
✅ Health Check
✅ Auto Scaling 기반 마련
```

## 🚀 **실행 계획**

### **우선순위 1: AI 서버 최적화**
```bash
cd terraform/environments/test
# main.tf에서 AI 모듈 수정
terraform plan  # 변경사항 확인
terraform apply # 적용
```

### **우선순위 2: Load Balancer 구현**
```bash
# LB 모듈 생성 후
terraform plan  # LB 추가 확인
terraform apply # 배포
```

### **우선순위 3: 모니터링 설정**
```bash
# AI 서버 메모리 사용량 모니터링
# 필요시 다시 e2-highmem-2로 업그레이드
```

---

## 🎯 **결론**

**AI 서버를 e2-standard-2로 다운그레이드**하여 Load Balancer 추가 비용을 상쇄하면서도:

✅ **총 비용**: $215.67/월 (예산 대비 22% 절약)  
✅ **적절한 아키텍처**: 진정한 3-tier 구조  
✅ **확장성**: 언제든 스펙 업그레이드 가능  
✅ **성능**: 초기 단계에는 충분한 스펙  

**가장 합리적인 선택**입니다!

이 방안으로 진행하시겠습니까?
