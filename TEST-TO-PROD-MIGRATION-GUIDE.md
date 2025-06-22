# 🚀 Test → Production 마이그레이션 가이드

이 가이드는 test 환경에서 검증된 설정을 production 환경으로 마이그레이션하는 절차입니다.

## 📋 사전 준비 체크리스트

### ✅ 인프라 준비
- [x] GCP 프로젝트 production 리소스 할당량 확인
- [x] production 도메인 (moongsan.com) DNS 설정 준비
- [x] SSL 인증서 도메인 소유권 확인
- [x] VPC 피어링을 위한 shared 환경 상태 확인

### ✅ 보안 준비
- [x] production용 강력한 패스워드 생성
- [x] Ansible Vault 패스워드 설정 완료
- [x] 운영 환경용 API 키 및 OAuth 클라이언트 준비
- [x] SSH 키 접근 권한 재검토

### ✅ 네트워크 준비
- [x] WireGuard VPN 설정 (10.1.0.0/16 대역 접근)
- [x] 방화벽 규칙 검토
- [x] 로드밸런서 설정 확인

## 🎉 PROD 환경 마이그레이션 완료 상태

### ✅ Terraform 인프라 (COMPLETED)
- [x] prod 디렉토리 구조 생성
- [x] variables.tf 설정 완료
- [x] main.tf URL Map 오류 수정 완료
- [x] `terraform apply` 성공 및 인프라 구축 완료
- [x] Load Balancer IP: 34.8.174.93 할당

### ✅ Ansible 구조 정리 (COMPLETED)
- [x] prod.ini 인벤토리 파일 생성 완료
- [x] group_vars/prod/all.yml 설정 완료 (test와 동일 구조)
- [x] group_vars/prod/vault.yml 암호화 완료
- [x] **민감 정보 vault화 완료**: AI, AWS, GCP 등 모든 민감 데이터 암호화
- [x] prod 환경 변수 참조 테스트 완료
- [x] test/prod 구조 완전 일치 확인

### ✅ 보안 강화 (COMPLETED)
- [x] 모든 민감 정보 vault 변수로 교체:
  - OpenAI API Key
  - Tavily API Keys  
  - LangSmith API Key
  - 프록시 설정
  - AWS IAM 자격증명
  - GCP 서비스 계정 Private Key들
- [x] vault.yml 파일 ansible-vault로 암호화 완료
- [x] vault 변수 참조 정상 동작 확인

### 🔧 Vault 변수 구조
```yaml
# 현재 vault.yml에 포함된 모든 민감 정보:
vault_mysql_prod_password          # MySQL 패스워드
vault_mysql_root_prod_password     # MySQL Root 패스워드  
vault_nginx_prod_password          # Nginx 사용자 패스워드
vault_kakao_client_id              # Kakao OAuth 클라이언트 ID
vault_dockerhub_password           # DockerHub 패스워드 (암호화)
vault_openai_api_key               # OpenAI API 키
vault_tavily_api_keys              # Tavily API 키들
vault_langsmith_api_key            # LangSmith API 키
vault_proxies                      # 프록시 목록
vault_aws_access_key               # AWS Access Key
vault_aws_secret_key               # AWS Secret Key
vault_gcp_private_key_id           # GCP 기본 Private Key ID
vault_gcp_private_key              # GCP 기본 Private Key
vault_gcp_backup_private_key_id    # GCP 백업용 Private Key ID
vault_gcp_backup_private_key       # GCP 백업용 Private Key
vault_gcp_ai_private_key_id        # GCP AI용 Private Key ID
vault_gcp_ai_private_key           # GCP AI용 Private Key
```

### 🔍 검증된 동작 확인
```bash
# 환경 변수 정상 로드 확인
ansible -i prod.ini all -m debug -a "var=service_name"

# Vault 변수 정상 참조 확인
echo "vault_test_password" | ansible -i prod.ini all -m debug -a "var=ai.openai_api_key" --vault-password-file=/dev/stdin

# 데이터베이스 패스워드 확인
echo "vault_test_password" | ansible -i prod.ini all -m debug -a "var=db.mysql.password" --vault-password-file=/dev/stdin

# AWS 자격증명 확인
echo "vault_test_password" | ansible -i prod.ini all -m debug -a "var=aws.iam.access_key" --vault-password-file=/dev/stdin
```

## 🏗️ 1단계: Test 환경 정리 및 Production 인프라 배포 (COMPLETED)

### ⚠️ Test 환경 리소스 정리 (선택사항)
```bash
# Test 환경이 더 이상 필요하지 않다면 리소스 정리하여 비용 절약
cd terraform/environments/test

# Test 환경 현재 상태 확인
terraform state list

# Test 환경 완전 삭제 (주의: 되돌릴 수 없음!)
terraform destroy -auto-approve

# 상태 파일 백업 후 정리
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform/

echo "✅ Test 환경 정리 완료 - 월 약 $227 비용 절약"
```

### Production 인프라 생성 전 확인
```bash
# prod 디렉토리로 이동
cd ../prod

# 변수 파일 확인 및 수정
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일에서 실제 값들로 수정:
# - project_id
# - domain (moongsan.com)
# - SSH 키 경로
# - GCS 버킷 이름 (전역 고유)
```

### Terraform 초기화 및 배포
```bash
# Terraform 초기화
terraform init

# Backend 설정 활성화 (상태 파일을 GCS에 저장)
# backend.tf 파일의 주석 해제

# 배포 계획 확인
terraform plan

# 인프라 배포 (약 5-10분 소요)
terraform apply

# 생성된 리소스 확인
terraform output

# ✅ 배포 성공 결과 (2024년 12월 기준)
# 로드밸런서 IP: 34.8.174.93
# 도메인: moongsan.com  
# VPC CIDR: 10.1.0.0/16
# 예상 월 비용: $233.04
# SSL 인증서: 자동 프로비저닝 중
```

### 예상 생성 리소스 (총 30+ 개)
- **네트워크**: VPC, 서브넷, 방화벽 규칙, VPC 피어링
- **VM**: database (e2-standard-2), backend (e2-standard-2), ai (e2-highmem-2)
- **로드밸런서**: Global HTTP(S) Load Balancer, SSL 인증서
- **스토리지**: GCS 버킷 (프론트엔드), CDN 설정

## 🔗 2단계: VPC 피어링 및 네트워크 연결 확인

### Shared 환경과의 피어링 확인
```bash
# Shared 환경에서 피어링 상태 확인
cd ../shared
terraform show | grep -A 3 "network_peering"

# 피어링이 INACTIVE라면 재적용
terraform apply
```

### 네트워크 연결 테스트
```bash
# WireGuard VPN 연결 (prod 대역 포함 설정 필요)
sudo wg-quick up your-prod-client.conf

# Prod 내부 네트워크 접근 테스트
ping 10.1.0.2  # prod-database
ping 10.1.0.3  # prod-backend  
ping 10.1.0.4  # prod-ai
```

## 🚀 3단계: Ansible Production 배포

### Vault 패스워드 설정
```bash
# Production용 vault 패스워드 설정
echo 'your-production-vault-password' > ~/.ansible_vault_pass_prod
chmod 600 ~/.ansible_vault_pass_pass_prod

# 또는 환경변수로 설정
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass_prod
```

### Vault 파일 암호화
```bash
cd ../../ansible

# Production vault 파일 암호화
ansible-vault encrypt group_vars/prod/vault.yml --vault-password-file ~/.ansible_vault_pass_prod

# 암호화 확인
cat group_vars/prod/vault.yml
# $ANSIBLE_VAULT;1.1;AES256으로 시작하는 암호화된 내용 확인
```

### Ansible 연결 테스트
```bash
# Production 인벤토리 연결 테스트
ansible -i prod.ini all -m ping --vault-password-file ~/.ansible_vault_pass_prod

# 예상 출력:
# shared-jumpbox | SUCCESS => { "ping": "pong" }
# prod-database | SUCCESS => { "ping": "pong" }
# prod-backend | SUCCESS => { "ping": "pong" }  
# prod-ai | SUCCESS => { "ping": "pong" }
```

### Production 전체 배포
```bash
# 🎯 Production 전체 배포 (약 10-15분 소요)
ansible-playbook -i prod.ini playbooks/main.yml --vault-password-file ~/.ansible_vault_pass_prod

# 또는 단계별 배포
ansible-playbook -i prod.ini playbooks/main.yml --tags "base" --vault-password-file ~/.ansible_vault_pass_prod
ansible-playbook -i prod.ini playbooks/main.yml --tags "database" --vault-password-file ~/.ansible_vault_pass_prod
ansible-playbook -i prod.ini playbooks/main.yml --tags "backend" --vault-password-file ~/.ansible_vault_pass_prod
ansible-playbook -i prod.ini playbooks/main.yml --tags "ai" --vault-password-file ~/.ansible_vault_pass_prod
ansible-playbook -i prod.ini playbooks/main.yml --tags "frontend" --vault-password-file ~/.ansible_vault_pass_prod
```

## ✅ 4단계: Production 배포 검증

### 서비스 상태 확인
```bash
# 모든 컨테이너 상태 확인
ansible -i prod.ini all -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" --vault-password-file ~/.ansible_vault_pass_prod

# MySQL 연결 확인
ansible -i prod.ini database -m shell -a "docker exec mysql-moongsan mysql -u root -p'pass' -e 'SHOW DATABASES;'" --vault-password-file ~/.ansible_vault_pass_prod

# Redis 마스터 모드 확인
ansible -i prod.ini database -m shell -a "docker exec redis-moongsan redis-cli INFO replication | grep role:master" --vault-password-file ~/.ansible_vault_pass_prod
```

### 웹 서비스 접근 테스트
```bash
# 도메인 접근 테스트 (DNS 전파 후)
curl -I https://moongsan.com

# 로드밸런서 IP 직접 접근
LB_IP=$(cd ../terraform/environments/prod && terraform output -raw load_balancer_ip)
curl -H "Host: moongsan.com" https://$LB_IP

# 백엔드 API 테스트
curl https://moongsan.com/api/health

# AI 서비스 테스트
curl https://moongsan.com/generation/health
```

## 🔧 5단계: DNS 및 도메인 설정 (중요!)

### 로드밸런서 IP 확인
```bash
# 로드밸런서 IP 확인
cd terraform/environments/prod
terraform output load_balancer_ip

# 출력 예시: 34.102.136.180
# 이 IP를 DNS 설정에 사용합니다
```

### DNS A 레코드 등록

#### 방법 1: 도메인 관리 콘솔에서 직접 설정
```
# 도메인 등록업체(가비아, 후이즈, 클라우드플레어 등) 관리 페이지에서:

1. DNS 관리 메뉴 접근
2. 다음 A 레코드 추가:

레코드 타입: A
호스트명: @ (또는 공백)
값: [로드밸런서 IP]  # 예: 34.102.136.180
TTL: 300 (5분)

레코드 타입: A  
호스트명: www
값: [로드밸런서 IP]  # 예: 34.102.136.180
TTL: 300 (5분)

3. 저장 후 전파 대기 (5분~24시간)
```

#### 방법 2: CLI로 확인 및 설정 (예시)
```bash
# 현재 DNS 상태 확인
dig moongsan.com
dig www.moongsan.com

# Cloud DNS 사용시 (구글 도메인)
gcloud dns record-sets transaction start --zone=moongsan-zone
gcloud dns record-sets transaction add [로드밸런서 IP] --name=moongsan.com. --ttl=300 --type=A --zone=moongsan-zone
gcloud dns record-sets transaction add [로드밸런서 IP] --name=www.moongsan.com. --ttl=300 --type=A --zone=moongsan-zone
gcloud dns record-sets transaction execute --zone=moongsan-zone
```

### DNS 전파 확인
```bash
# DNS 전파 상태 실시간 확인
while true; do
  echo "=== $(date) ==="
  echo "moongsan.com:"
  dig +short moongsan.com
  echo "www.moongsan.com:"
  dig +short www.moongsan.com
  echo "---"
  sleep 60
done

# 전파 완료 시 로드밸런서 IP가 출력됨
```

### 도메인 접근 테스트 (DNS 전파 후)
```bash
# 기본 도메인 접근
curl -I https://moongsan.com

# www 서브도메인 접근
curl -I https://www.moongsan.com

# 로드밸런서 IP 직접 접근 (DNS 전파 전 테스트용)
LB_IP=$(terraform output -raw load_balancer_ip)
curl -H "Host: moongsan.com" https://$LB_IP

# 백엔드 API 테스트
curl https://moongsan.com/api/health

# AI 서비스 테스트  
curl https://moongsan.com/generation/health
```

### SSL 인증서 자동 발급 및 검증
```bash
# SSL 인증서 상태 확인
gcloud compute ssl-certificates describe prod-ssl-cert --global

# 상태 확인 (PROVISIONING -> ACTIVE 변화 확인)
while true; do
  STATUS=$(gcloud compute ssl-certificates describe prod-ssl-cert --global --format="value(managed.status)")
  echo "$(date): SSL Certificate Status = $STATUS"
  
  if [ "$STATUS" = "ACTIVE" ]; then
    echo "✅ SSL 인증서 발급 완료!"
    break
  elif [ "$STATUS" = "FAILED_NOT_VISIBLE" ]; then
    echo "❌ DNS 설정 확인 필요 - A 레코드가 올바르게 설정되었는지 확인하세요"
    break
  else
    echo "⏳ 인증서 발급 진행 중... (최대 60분 소요)"
  fi
  
  sleep 300  # 5분마다 확인
done

# SSL 등급 테스트 (인증서 발급 완료 후)
echo "SSL Labs 테스트: https://www.ssllabs.com/ssltest/analyze.html?d=moongsan.com"
```

### SSL/HTTPS 접근 테스트
```bash
# HTTPS 접근 확인
curl -I https://moongsan.com

# SSL 인증서 정보 확인
openssl s_client -connect moongsan.com:443 -servername moongsan.com < /dev/null 2>/dev/null | openssl x509 -text -noout

# HTTP → HTTPS 리다이렉션 확인
curl -I http://moongsan.com
```

## 📊 6단계: 성능 및 보안 검증

### 성능 테스트
```bash
# 응답 시간 테스트
curl -w "@curl-format.txt" -o /dev/null -s https://moongsan.com

# 동시 연결 테스트 (간단한 부하 테스트)
ab -n 100 -c 10 https://moongsan.com/
```

### 보안 검증
```bash
# SSL 등급 확인
curl -I https://moongsan.com | grep -i "strict-transport-security"

# 포트 스캔 테스트 (내부에서)
nmap -p 22,80,443,3306,6379,8080,8100 10.1.0.2
```

## 🚨 트러블슈팅

### 일반적인 문제들

1. **Terraform URL Map 오류 (PathMatcher not referenced)**
   ```bash
   # 문제: URL Map에서 path_matcher가 host_rule에 연결되지 않음
   # 해결: host_rule 추가 및 path_matcher 구조 수정
   
   # 오류 예시
   Error: Error creating UrlMap: googleapi: Error 400: The resource 'projects/xxx/global/urlMaps/prod-url-map' is not valid. The PathMatcher 'api-matcher' is not referenced by any HostRule.
   
   # 해결책: main.tf에서 URL Map 구조 수정
   resource "google_compute_url_map" "prod_url_map" {
     name            = "prod-url-map"
     default_service = google_compute_backend_bucket.prod_cdn_backend.id

     # host_rule 추가 (필수)
     host_rule {
       hosts        = [var.domain]
       path_matcher = "api-matcher"
     }

     path_matcher {
       name            = "api-matcher"
       default_service = google_compute_backend_bucket.prod_cdn_backend.id
       # ... path_rule들
     }
   }
   ```

2. **DNS 전파 지연**
   ```bash
   # 다양한 DNS 서버에서 확인
   dig @8.8.8.8 moongsan.com        # Google DNS
   dig @1.1.1.1 moongsan.com        # Cloudflare DNS
   dig @208.67.222.222 moongsan.com # OpenDNS
   
   # 전 세계 DNS 전파 상태 확인
   echo "https://www.whatsmydns.net/#A/moongsan.com"
   ```

2. **SSL 인증서 발급 실패**
   ```bash
   # 도메인 소유권 확인
   dig moongsan.com
   # 결과가 로드밸런서 IP와 일치하는지 확인
   
   # DNS CAA 레코드 확인 (SSL 발급 제한 여부)
   dig CAA moongsan.com
   
   # 인증서 재발급 시도
   gcloud compute ssl-certificates delete prod-ssl-cert --global
   # terraform apply로 재생성
   ```

3. **도메인 접근 실패 (404/502 에러)**
   ```bash
   # 로드밸런서 백엔드 상태 확인
   gcloud compute backend-services get-health prod-backend-service --global
   gcloud compute backend-services get-health prod-ai-service --global
   
   # 인스턴스 그룹 상태 확인
   gcloud compute instance-groups list-instances prod-backend-group --zone=asia-northeast3-a
   ```

4. **VPC 피어링 문제**
   ```bash
   # 피어링 상태 확인
   gcloud compute networks peerings list
   # INACTIVE인 경우 shared 환경 재적용
   cd terraform/environments/shared && terraform apply
   ```

5. **Test 환경 정리 후 접근 문제**
   ```bash
   # Test 환경 삭제로 인한 WireGuard 설정 확인
   ping 10.1.0.2  # prod 환경 접근 확인
   
   # WireGuard 클라이언트 설정 업데이트 필요시
   # AllowedIPs = 10.1.0.0/16 (prod만) 또는 10.0.0.0/8 (전체)
   ```

6. **Vault 복호화 실패**
   ```bash
   # 올바른 vault 패스워드 파일 사용 확인
   ansible-vault view group_vars/prod/vault.yml --vault-password-file ~/.ansible_vault_pass_prod
   ```

7. **컨테이너 실행 실패**
   ```bash
   # 컨테이너 로그 확인
   ansible -i prod.ini backend -m shell -a "docker logs be-moongsan --tail 50"
   
   # 이미지 pull 문제 시
   ansible -i prod.ini all -m shell -a "docker system prune -a -f"
   ```

8. **DNS 캐시 문제**
   ```bash
   # 로컬 DNS 캐시 초기화 (macOS)
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   
   # 다른 네트워크에서 접근 테스트
   # 모바일 핫스팟 등 사용
   ```

## 📈 7단계: 모니터링 및 알림 설정

### 기본 모니터링 확인
```bash
# VM 리소스 사용량 확인
ansible -i prod.ini all -m shell -a "free -h && df -h"

# 서비스 포트 확인
ansible -i prod.ini all -m shell -a "netstat -tlnp"
```

### 로그 수집 설정
```bash
# 애플리케이션 로그 확인
ansible -i prod.ini backend -m shell -a "docker logs be-moongsan --since 1h"
ansible -i prod.ini ai -m shell -a "docker logs ai-moongsan --since 1h"
```

## 🎯 8단계: 운영 준비 완료 체크리스트

### ✅ 인프라 레벨
- [ ] Test 환경 정리 완료 (선택사항 - 비용 절약)
- [ ] 모든 Terraform 리소스 정상 생성 (30+ 개)
- [ ] VPC 피어링 ACTIVE 상태 (shared ↔ prod)
- [ ] 로드밸런서 헬스체크 HEALTHY 상태

### ✅ DNS 및 도메인 레벨
- [ ] DNS A 레코드 등록 완료 (moongsan.com, www.moongsan.com)
- [ ] DNS 전파 완료 확인 (dig 명령으로 로드밸런서 IP 반환)
- [ ] SSL 인증서 발급 완료 및 ACTIVE 상태
- [ ] HTTPS 접근 정상 동작 (curl -I https://moongsan.com)

### ✅ 애플리케이션 레벨
- [ ] **Database**: MySQL, Redis, MongoDB 모든 컨테이너 실행
- [ ] **Backend**: Spring Boot API 컨테이너 실행 (포트 8080)
- [ ] **AI**: FastAPI 서비스 컨테이너 실행 (포트 8100)
- [ ] **Frontend**: GCS + CDN 배포 완료

### ✅ 네트워크 레벨
- [ ] 도메인 접근: https://moongsan.com 정상 응답
- [ ] www 서브도메인: https://www.moongsan.com 정상 응답
- [ ] API 엔드포인트: /api/*, /generation/* 정상 라우팅
- [ ] SSL/TLS: A급 보안 등급 확인
- [ ] CDN: 정적 리소스 캐싱 정상 동작

### ✅ 보안 레벨
- [ ] Ansible Vault 암호화 적용
- [ ] 강력한 패스워드 사용 (운영 환경)
- [ ] SSH 키 기반 인증만 허용
- [ ] 방화벽 규칙 최소 권한 원칙 적용

## 🎉 마이그레이션 완료!

모든 체크리스트가 완료되면 **Production 환경이 성공적으로 배포**된 것입니다.

### 다음 단계
1. **모니터링 강화**: Prometheus, Grafana 등 구축
2. **백업 자동화**: 데이터베이스 정기 백업 스케줄 설정
3. **CI/CD 파이프라인**: 자동화된 배포 파이프라인 구축
4. **장애 대응**: 온콜 체계 및 복구 프로세스 정립

---

## 📊 비용 분석 (Test → Production 마이그레이션)

### 기존 Test 환경 비용
| 구성요소 | 사양 | 월 비용 |
|----------|------|---------|
| Jump Box | e2-small (0.5 vCPU, 2GB) | $13.84 |
| Database VM | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| Backend VM | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| AI VM | e2-highmem-2 (2 vCPU, 16GB) | $80.96 |
| Storage & Network | - | $25.89 |
| **Test 환경 총 비용** | - | **$227.77/월** |

### Production 환경 비용
| 구성요소 | 사양 | 월 비용 |
|----------|------|---------|
| Database VM | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| Backend VM | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| AI VM | e2-highmem-2 (2 vCPU, 16GB) | $80.96 |
| Global Load Balancer | HTTPS LB | $18.00 |
| SSL Certificate | Google Managed | $0.00 |
| Storage & Network | GCS + CDN | $27.00 |
| **Production 환경 총 비용** | - | **$233.04/월** |

### 비용 최적화 전략

#### 옵션 1: Test + Production 병행 운영
- **총 비용**: $227.77 + $233.04 = **$460.81/월**
- **장점**: 개발/테스트 환경 유지, 안전한 배포 테스트 가능
- **단점**: 비용 부담 증가

#### 옵션 2: Test 환경 정리 후 Production 단독 운영 (권장)
- **총 비용**: $233.04/월 (Test 환경 $227.77 절약)
- **절약 효과**: 월 $227.77 절약, 연간 약 $2,733 절약
- **장점**: 비용 효율적, 운영 복잡도 감소
- **단점**: 별도 개발 환경 필요시 재구축 필요

#### 옵션 3: 필요시 Test 환경 임시 생성
```bash
# 개발/테스트 필요시에만 임시 생성
terraform apply   # 테스트 시작
terraform destroy # 테스트 완료 후 삭제

# 월 5일 사용시: $227.77 × (5/30) = 약 $38/월
```

### 💰 권장 비용 운영 방안
1. **즉시**: Test 환경 정리하여 월 $227 절약
2. **단기**: Production 단독 운영 ($233/월)
3. **장기**: 개발팀 규모에 따라 별도 Dev 환경 고려

**결론**: Test 환경 정리 시 **연간 약 $2,733 절약 가능**
