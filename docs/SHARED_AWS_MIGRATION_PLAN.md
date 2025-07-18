# 🔄 Shared 환경 AWS 마이그레이션 계획서

> **문서 목표**: GCP 크레딧 부족 문제를 해결하기 위해 Shared 환경(ELK Stack, WireGuard VPN)을 AWS로 이전하는 세부 계획을 수립합니다.

## 📋 현재 상황 (2025-07-16 기준)

### ✅ 이미 AWS로 이전 완료
- **Jenkins**: `aws-shared-jenkins` (3.38.150.190)
- **도메인**: `jenkins.moongsan.com:8080`

### ❌ GCP에서 AWS로 이전 필요
- **ELK Stack**: `shared-elk` (`elk.moongsan.com`)
  - Elasticsearch (9200)
  - Kibana (5601) 
  - Logstash (5044)
  - APM Server (8200)
- **WireGuard VPN**: `shared-jumpbox` (34.22.110.81)

## 🎯 마이그레이션 목표

### 1단계: ELK Stack AWS 이전 (우선순위 1) ✅ **완료 (2025-07-16)**
**목표**: 로그 모니터링 시스템을 AWS로 이전하여 비용 절감

**작업 내용**:
- [x] AWS EC2 인스턴스 생성 (`aws-shared-elk`) - **완료 (43.203.65.98)**
- [x] ELK Stack 설정 파일 적용 - **완료 (Ansible 자동화)**
- [x] HTTPS SSL 인증서 설정 - **완료 (Let's Encrypt)**
- [x] 기존 인덱스/데이터 마이그레이션 (선택사항) - **스킵 (새로 시작)**
- [x] DNS 레코드 설정 (`elk.test.moongsan.com`) - **완료**
- [x] 방화벽/보안 그룹 설정 - **완료 (80, 443, 5601, 9200 포트)**

**실제 소요 시간**: 1일 (Ansible 플레이북으로 완전 자동화)
**최종 URL**: https://elk.test.moongsan.com (HTTPS 자동 리다이렉트)

### 2단계: WireGuard VPN AWS 이전 (우선순위 2) 🔄 **진행 중**
**목표**: VPN 서버를 AWS로 이전하여 통합 관리

**작업 내용**:
- [ ] AWS EC2 인스턴스 생성 (`aws-shared-jumpbox`)
- [ ] WireGuard Ansible 플레이북 개발
- [ ] WireGuard 설정 자동화 배포
- [ ] 클라이언트 설정 파일 업데이트 (팀원 배포)
- [ ] 기존 GCP jumpbox 정리

**예상 소요 시간**: 1일 (Ansible 자동화로 단축)

## 📊 비용 영향 분석

### GCP → AWS 이전 시 예상 비용 절감
- **ELK Stack**: e2-standard-2 (GCP) → t3.medium (AWS)
- **WireGuard**: e2-micro (GCP) → t3.micro (AWS)
- **예상 월 절감액**: ~$50-80

## 🚀 실행 계획

### Phase 1: ELK Stack 이전 (즉시 실행)

#### Step 1.1: AWS 인프라 준비
```bash
# AWS EC2 인스턴스 생성 (콘솔에서 수행)
# - 인스턴스 타입: t3.medium
# - OS: Ubuntu 22.04 LTS
# - 보안 그룹: ELK Stack 포트 개방
# - 키페어: 기존 SSH 키 사용
```

#### Step 1.2: ELK Stack 설치 및 설정
```bash
# Ansible 플레이북으로 자동 설치
ansible-playbook -i aws-shared.ini playbooks/deploy_elk.yml
```

#### Step 1.3: 데이터 마이그레이션 (선택사항)
```bash
# 기존 인덱스 백업 및 복원
# 또는 새로 시작 (로그 데이터는 실시간 수집)
```

#### Step 1.4: DNS 및 서비스 전환
```bash
# elk.moongsan.com A 레코드 업데이트
# 기존 GCP 서비스 중지
```

### Phase 2: WireGuard VPN 이전 (ELK 완료 후)

#### Step 2.1: AWS jumpbox 생성
```bash
# t3.micro 인스턴스 생성
# WireGuard 설치 및 설정
```

#### Step 2.2: 클라이언트 설정 업데이트
```bash
# 팀원별 WireGuard 설정 파일 업데이트
# 새로운 서버 IP로 변경
```

## 🔄 Cross-cloud 네트워킹 고려사항

### AWS ↔ GCP 연결 방안
1. **VPN 터널링**: AWS VPN Gateway ↔ GCP Cloud VPN
2. **WireGuard 기반**: AWS jumpbox를 중계점으로 활용
3. **인터넷 기반**: Public IP를 통한 연결 (현재 방식 유지)

### 권장 방안: 인터넷 기반 연결 유지
- **이유**: 설정 복잡도 최소화, 비용 효율성
- **보안**: WireGuard VPN + SSH 키 기반 인증으로 충분

## 📅 예상 일정

### 주간별 계획
- **1주차**: ELK Stack AWS 이전
  - Day 1-2: AWS 인프라 구성
  - Day 3-4: ELK 설치 및 설정
  - Day 5: 테스트 및 DNS 전환
- **2주차**: WireGuard VPN 이전
  - Day 1-2: AWS jumpbox 구성
  - Day 3-4: 클라이언트 설정 업데이트
  - Day 5: 기존 GCP 리소스 정리

## ⚠️ 리스크 및 대응방안

### 주요 리스크
1. **로그 데이터 손실**: 이전 중 로그 수집 중단
2. **VPN 연결 중단**: 팀원 작업 환경 영향
3. **서비스 다운타임**: DNS 변경 시 일시적 접근 불가

### 대응방안
1. **점진적 이전**: 새 서비스 구성 후 DNS 전환
2. **백업 계획**: 기존 서비스 병렬 운영 후 전환
3. **롤백 절차**: 문제 발생 시 즉시 원복 가능한 계획

## ✅ 완료 기준

### ELK Stack 이전 완료 ✅
- [x] AWS ELK 서비스 정상 작동
- [x] 모든 서버에서 로그 수집 확인
- [x] Kibana 대시보드 정상 접근 (HTTPS)
- [x] APM 데이터 수집 확인

### WireGuard VPN 이전 완료
- [ ] AWS jumpbox 정상 작동
- [ ] 모든 팀원 VPN 연결 테스트
- [ ] 내부 서버 SSH 접근 확인
- [ ] 기존 GCP jumpbox 종료

## 📝 변경 로그 (CHANGELOG)

### 2025-07-16: ELK Stack AWS 마이그레이션 완료
#### ✅ 완료된 작업
- **AWS 인프라 구성**: EC2 t3.medium (43.203.65.98), 보안그룹 설정
- **Ansible 자동화**: `deploy_aws_elk_new.yml` 플레이북 개발 (37개 태스크)
- **ELK Stack 설치**: Elasticsearch 8.18.3, Kibana 8.18.3, Logstash 설치
- **HTTPS 보안 설정**: Let's Encrypt SSL 인증서, nginx 리버스 프록시
- **DNS 설정**: elk.test.moongsan.com A 레코드 설정
- **포트 설정**: 80(HTTP→HTTPS 리다이렉트), 443(HTTPS), 5601(Kibana), 9200(Elasticsearch)

#### 🔧 기술적 개선사항
- **메모리 최적화**: Elasticsearch JVM heap 1GB 설정
- **보안 강화**: HTTPS 강제 리다이렉트, SSL 보안 헤더 적용
- **자동화 구현**: nginx_conf 롤 활용한 템플릿 기반 설정
- **모니터링**: 서비스 상태 자동 확인 및 포트 검증

#### ⚠️ 트러블슈팅 해결
- **Elasticsearch 권한 문제**: log 디렉토리 소유권 수정
- **Kibana 설정 충돌**: 단순화된 설정으로 호환성 개선
- **nginx 템플릿 경로**: 상대 경로 문제 해결

### 2025-07-17: WireGuard VPN 마이그레이션 시작
#### 🔄 진행 예정
- AWS EC2 인스턴스 생성 (t3.micro)
- WireGuard Ansible 플레이북 개발
- 기존 클라이언트 설정 이전

## 🚨 트러블슈팅 가이드

### ELK Stack 관련 문제

#### 1. Elasticsearch 서비스 시작 실패
**증상**: `systemctl start elasticsearch` 실패
**원인**: 권한 문제 또는 메모리 부족
**해결방법**:
```bash
# 로그 디렉토리 권한 확인
sudo chown -R elasticsearch:elasticsearch /var/log/elasticsearch
sudo chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# JVM 힙 메모리 확인
sudo nano /etc/elasticsearch/jvm.options
# -Xms1g, -Xmx1g 설정 확인
```

#### 2. Kibana 연결 오류
**증상**: Kibana UI 접근 불가, "Kibana server is not ready yet"
**원인**: Elasticsearch 연결 문제
**해결방법**:
```bash
# Elasticsearch 상태 확인
curl -X GET "localhost:9200/_cluster/health"

# Kibana 설정 확인
sudo nano /etc/kibana/kibana.yml
# elasticsearch.hosts 설정 확인
```

#### 3. SSL 인증서 발급 실패
**증상**: Let's Encrypt 인증서 발급 오류
**원인**: DNS 전파 지연 또는 도메인 접근 불가
**해결방법**:
```bash
# DNS 전파 확인
nslookup elk.test.moongsan.com

# 수동 인증서 발급
sudo certbot --nginx -d elk.test.moongsan.com --dry-run
```

#### 4. HTTP → HTTPS 리다이렉트 안됨
**증상**: HTTP 접속 시 HTTPS로 리다이렉트되지 않음
**원인**: nginx 설정 문제
**해결방법**:
```bash
# nginx 설정 테스트
sudo nginx -t

# 설정 파일 확인
sudo nano /etc/nginx/sites-available/default
```

### 일반적인 AWS 관련 문제

#### 1. 보안그룹 포트 차단
**증상**: 서비스는 실행되지만 외부 접근 불가
**해결방법**: AWS 콘솔에서 보안그룹 인바운드 규칙 확인

#### 2. DNS 전파 지연
**증상**: 도메인 접근 불가
**해결방법**: DNS 전파 대기 (최대 24시간) 또는 직접 IP 접근 테스트

## 🎯 다음 단계

1. **즉시 시작**: ELK Stack AWS 이전
2. **병렬 진행**: Prod 환경 AWS 마이그레이션 계획 수립
3. **최종 목표**: 전체 시스템 AWS 통합 완료

---

**작성일**: 2025-07-16  
**작성자**: GitHub Copilot  
**업데이트**: 필요시 지속적으로 업데이트
