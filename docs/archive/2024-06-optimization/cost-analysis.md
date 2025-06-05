# 💰 GCP 인프라 비용 분석 (Test 환경)

## 📊 현재 구성 요약

### Compute Engine 인스턴스 (4대)
1. **Jump Box** (WireGuard 서버)
   - 머신 타입: `e2-medium` (2 vCPU, 4GB RAM)
   - 디스크: 20GB SSD 
   - 외부 IP: 1개 (고정 IP)
   - 용도: VPN 서버, 보안 게이트웨이

2. **Backend 서버**
   - 머신 타입: `e2-standard-2` (2 vCPU, 8GB RAM)
   - 디스크: 20GB SSD
   - 외부 IP: 없음 (내부 전용)
   - 용도: Spring Boot API 서버

3. **AI 서버**
   - 머신 타입: `e2-highmem-2` (2 vCPU, 16GB RAM)
   - 디스크: 20GB SSD
   - 외부 IP: 없음 (내부 전용)
   - 용도: FastAPI 기반 AI 서비스

4. **Database 서버**
   - 머신 타입: `e2-standard-2` (2 vCPU, 8GB RAM)
   - 디스크: 100GB SSD
   - 외부 IP: 없음 (내부 전용)
   - 용도: MySQL 데이터베이스

### 네트워크 리소스
- VPC 네트워크: 1개 (무료)
- 서브넷: 1개 (무료)
- 방화벽 규칙: 여러 개 (무료)
- 고정 외부 IP: 1개

### 스토리지 리소스
- GCS 버킷: 2개 (Terraform 상태 + Frontend)
- KMS 키: 1개 (Terraform 상태 암호화용)

## 💵 월별 예상 비용 (서울 리전, asia-northeast3)

### Compute Engine 비용
```
Jump Box (e2-medium):
- VM: $24.27/월 (24시간 운영)
- SSD 20GB: $3.40/월
- 고정 외부 IP: $7.30/월
- 소계: $34.97/월

Backend (e2-standard-2):
- VM: $48.55/월 (24시간 운영)  
- SSD 20GB: $3.40/월
- 소계: $51.95/월

AI (e2-highmem-2):
- VM: $65.70/월 (24시간 운영, 메모리 집약적)
- SSD 20GB: $3.40/월
- 소계: $69.10/월

Database (e2-standard-2):
- VM: $48.55/월 (24시간 운영)
- SSD 100GB: $17.00/월
- 소계: $65.55/월

Compute 총계: $221.57/월
```

### 네트워크 비용
```
- 내부 트래픽: 무료
- 외부 송신 (첫 1GB): 무료
- 외부 송신 (1GB 초과시): $0.12/GB
- 예상 송신량 10GB/월: $1.08/월

네트워크 총계: ~$1.08/월
```

### 스토리지 비용
```
GCS (Terraform 상태):
- Standard 스토리지 ~1GB: $0.02/월
- 버전 관리로 인한 추가 용량: $0.05/월

GCS (Frontend):
- Standard 스토리지 ~5GB: $0.10/월
- CDN 트래픽 (10GB/월): $1.20/월

KMS:
- 키 사용료: $0.06/월
- 암호화/복호화 작업: ~$0.03/월

스토리지 총계: ~$1.46/월
```

## 📈 총 예상 비용

### 💰 **월 총 비용: 약 $224/월 (₩292,000/월)**

#### 비용 구성:
- **Compute Engine**: $221.57/월 (98.9%)
- **네트워크**: $1.08/월 (0.5%)  
- **스토리지**: $1.46/월 (0.6%)

### 🔄 운영 시간에 따른 절약
만약 개발/테스트 환경을 주간만 운영한다면:
- **주간 운영 (12시간/일, 5일/주)**: 약 25% 절약 → **$168/월**
- **야간 중지 (8시간/일 운영)**: 약 67% 절약 → **$74/월**

## 💡 비용 최적화 방안

### 1. 즉시 적용 가능
```bash
# 개발 중이 아닐 때 인스턴스 중지
gcloud compute instances stop [INSTANCE_NAME] --zone=asia-northeast3-a

# 필요할 때만 시작
gcloud compute instances start [INSTANCE_NAME] --zone=asia-northeast3-a
```

### 2. 아키텍처 최적화
- **Preemptible VM 사용**: 70% 비용 절약 (단, 24시간 내 중단 가능)
- **더 작은 머신 타입**: AI 서버를 `e2-standard-2`로 변경 시 $16/월 절약
- **디스크 최적화**: Standard PD 사용 시 20% 절약

### 3. 단계적 배포
1. **Phase 1**: Jump Box + Database만 배포 → **$100/월**
2. **Phase 2**: Backend 추가 → **$152/월**  
3. **Phase 3**: AI 서버 추가 → **$224/월**

## ⚠️ 주의사항

### 예상치 못한 비용
- **대용량 트래픽**: 외부 송신량 급증 시
- **스토리지 급증**: 로그, 백업 파일 누적
- **KMS 작업**: 빈번한 암복호화 시

### 모니터링 설정
```bash
# 빌링 알람 설정 (권장)
gcloud alpha billing budgets create \
  --billing-account=[BILLING_ACCOUNT_ID] \
  --display-name="Monthly Budget Alert" \
  --budget-amount=300 \
  --threshold-rules-percent=0.8,1.0
```

## 🎯 권장사항

### 💚 프로덕션 진입 전 테스트
1. **부분 배포로 테스트**: Jump Box + Database만 먼저 배포
2. **비용 모니터링**: 첫 주간 일일 체크
3. **자동 중지 스케줄링**: 개발 시간 외 자동 중지

### 🛡️ 비용 보호 조치
- **Budget Alert**: $250/월 설정
- **Resource Labels**: 비용 추적용 라벨링
- **Auto-Shutdown**: 야간/주말 자동 중지

---

> 💡 **결론**: 현재 구성으로 **월 $224 (₩292,000)** 예상. 운영 시간 조정으로 50-70% 절약 가능!
