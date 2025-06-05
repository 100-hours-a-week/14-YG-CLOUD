# 💾 현재 디스크 구성 및 Jump Box 최적화 분석

## 📊 현재 디스크 구성

| 서버 | 머신 타입 | 디스크 크기 | 디스크 타입 | 용도 | 디스크 비용/월 |
|------|-----------|-------------|-------------|------|----------------|
| **Jump Box** | `e2-medium` | 50GB (기본값) | `pd-standard` | 시스템 + WireGuard | $8.50 |
| **Backend** | `e2-standard-2` | 50GB (기본값) | `pd-standard` | 시스템 + Spring Boot | $8.50 |
| **AI** | `e2-highmem-2` | 50GB (기본값) | `pd-standard` | 시스템 + AI 모델 | $8.50 |
| **Database** | `e2-standard-2` | **100GB (명시적)** | `pd-standard` | 시스템 + MySQL 데이터 | $17.00 |

### 📝 디스크 상세 분석

#### Standard Persistent Disk (`pd-standard`) 가격:
- **$0.17/GB/월** (서울 리전)
- HDD 기반으로 저렴하지만 성능은 낮음

#### SSD Persistent Disk (`pd-ssd`) 비교:
- **$0.34/GB/월** (2배 비싸지만 훨씬 빠름)

## 🎯 Jump Box를 `e2-small`로 변경 분석

### 💰 비용 절약 효과

#### 현재 Jump Box (`e2-medium`):
```bash
VM 비용: $24.27/월
디스크 비용: $8.50/월 (50GB)
총 비용: $32.77/월
```

#### 변경 후 Jump Box (`e2-small`):
```bash
VM 비용: $10.70/월 (56% 절약!)
디스크 비용: $8.50/월 (변경 없음)
총 비용: $19.20/월 (41% 절약!)

월 절약액: $13.57
```

### ✅ `e2-small`이 적합한 이유

#### Jump Box 실제 사용량:
```bash
# 운영체제: ~3GB
# WireGuard: ~10MB
# SSH 데몬: ~5MB
# 로그 파일: ~100MB
# 여유 공간: ~15GB

총 필요 용량: ~20GB
현재 할당: 50GB → 과도함!
```

#### `e2-small` 성능 충분성:
```bash
CPU: 0.5 vCPU (버스트 가능)
메모리: 2GB
- WireGuard 처리: 충분
- SSH 연결 5-10명: 문제없음
- 개인/소규모 팀: 완벽
```

## 🔧 최적화 권장사항

### 1. Jump Box 최적화
```hcl
# terraform/environments/test/main.tf
module "jumpbox" {
  # ...기존 설정...
  machine_type = "e2-small"    # e2-medium → e2-small
  disk_size    = 20           # 50GB → 20GB
  # ...나머지 설정...
}
```

#### 절약 효과:
- **VM**: $13.57/월 절약
- **디스크**: $5.10/월 절약 (30GB 감소)
- **총 절약**: $18.67/월 (57% 절약!)

### 2. 전체 디스크 최적화

#### 각 서버별 실제 필요 용량:
```bash
Jump Box: 20GB (시스템 + WireGuard)
Backend: 30GB (시스템 + Spring Boot + 로그)
AI: 40GB (시스템 + AI 모델 + 캐시)
Database: 100GB (시스템 + MySQL 데이터)
```

#### 최적화된 설정:
```hcl
# Jump Box
disk_size = 20  # 50GB → 20GB (-$5.10/월)

# Backend
disk_size = 30  # 50GB → 30GB (-$3.40/월)

# AI 서버 (AI 모델 때문에 여유 필요)
disk_size = 50  # 현재 유지

# Database
disk_size = 100 # 현재 유지 (데이터 성장 고려)
```

### 3. 성능 최적화 (선택사항)

Database만 SSD로 변경:
```hcl
# Database VM만
disk_type = "pd-ssd"  # 성능 중요
# 비용: $17 → $34/월 (+$17, 하지만 성능 대폭 향상)
```

## 📊 최적화 후 전체 비용 비교

### 현재 구성:
```bash
Jump Box: $32.77/월
Backend: $56.95/월  
AI: $77.60/월
Database: $65.55/월
총합: $232.87/월
```

### 최적화 후 (권장):
```bash
Jump Box: $14.10/월 (e2-small + 20GB)
Backend: $45.15/월 (30GB 디스크)  
AI: $77.60/월 (현재 유지)
Database: $65.55/월 (현재 유지)
총합: $202.40/월

월 절약: $30.47 (13% 절약!)
```

### 공격적 최적화 (개인 학습용):
```bash
Jump Box: $14.10/월 (e2-small + 20GB)
Backend: $35.25/월 (e2-small + 30GB)
AI: $44.20/월 (e2-small + 40GB)  
Database: $65.55/월 (현재 유지)
총합: $159.10/월

월 절약: $73.77 (32% 절약!)
```

## 🎯 실행 방안

### 즉시 적용 가능한 변경:

```bash
# 1. Jump Box 최적화
cd terraform/environments/test
vim main.tf
```

Jump Box 설정 변경:
```hcl
module "jumpbox" {
  # ...기존 설정...
  machine_type = "e2-small"    # 변경
  disk_size    = 20           # 변경
  # ...
}
```

### 단계적 적용:
1. **1단계**: Jump Box만 최적화 → **$18.67/월 절약**
2. **2단계**: Backend/AI 디스크 최적화 → **추가 $11.80/월 절약**
3. **3단계**: 필요시 머신 타입도 최적화

## 💡 결론

### ✅ `e2-small` 사용 강력 권장!

**이유:**
- Jump Box 용도로는 완전히 충분
- 57% 비용 절약 ($32.77 → $14.10)
- 성능 문제 없음 (개인/소규모 팀)
- 언제든 확장 가능

**디스크 최적화도 함께 적용하면 월 $30+ 절약!**

지금 바로 설정을 변경해보시겠어요?
