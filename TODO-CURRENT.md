# 현재 진행 상황 및 할 일 목록

## 📋 현재 상태 (2025년 6월 11일)

### ✅ 완료된 작업
- **인프라 복구**: dev, prod, test 환경 모든 서비스 정상 작동
- **백엔드 배포**: Spring Boot + MongoDB + Redis 컨테이너 모두 실행 중
- **VPC 방화벽**: 내부 통신 허용 규칙 적용 완료
- **MySQL 서비스**: 데이터베이스 서버에서 정상 실행 중
- **MySQL 사용자**: `moongsan_admin` 사용자 권한 설정 완료
- **VPC 피어링**: management-vpc ↔ test-vpc 피어링 설정 완료 (ACTIVE)
- **test-jumpbox 제거**: Terraform으로 깔끔하게 제거 완료
- **shared-jumpbox 설정**: SSH 키 복사 및 접근 구조 완성

### 🔴 현재 문제점
- **SSH 연결 실패**: shared-jumpbox에서 test 환경 서버들로 SSH 연결 불가 (포트 22 타임아웃)
- **VPC 라우팅 문제**: VPC 피어링은 ACTIVE이지만 실제 네트워크 연결 안됨
- **MySQL 연결 테스트 불가**: SSH 접근이 안되어 MySQL 연결 테스트 진행 불가

## 🎯 우선순위별 할 일

### 1단계: 긴급 (MySQL 연결 문제 해결)
- [ ] **MySQL 연결 테스트**
  - 백엔드에서 `telnet 10.0.0.2 3306` 또는 `nc -zv 10.0.0.2 3306` 테스트
  - 방화벽 규칙 적용 상태 확인
- [ ] **네트워크 진단**
  - VPC 내부 통신 확인 (`ping 10.0.0.2`)
  - 포트별 연결 테스트 (3306, 22, 27017, 6379)
- [ ] **Spring Boot 재시작**
  - MySQL 연결 문제 해결 후 백엔드 컨테이너 재시작
  - 애플리케이션 로그 확인

### 2단계: 중요 (서비스 배포 완성)
- [ ] **AI 서비스 배포**
  - FastAPI AI 서비스를 AI 서버(10.0.0.4)에 배포
  - Docker 컨테이너로 실행
  - 백엔드와 AI 서비스 간 통신 테스트
- [ ] **서비스 통합 테스트**
  - 백엔드 ↔ 데이터베이스 연결 테스트
  - 백엔드 ↔ AI 서비스 연결 테스트
  - 백엔드 ↔ Redis 연결 테스트
  - 백엔드 ↔ MongoDB 연결 테스트

### 3단계: 아키텍처 개선
- [ ] **VPC 분리 전략 구현**
  - dev: 10.0.0.0/16
  - test: 10.1.0.0/16
  - prod: 10.2.0.0/16
- [ ] **VPC 피어링 설정**
  - management-vpc ↔ test-vpc 피어링
  - 공유 점프박스를 통한 접근 구조 완성
- [ ] **불필요한 리소스 정리**
  - `moongsan-test-jumpbox` 제거
  - 중복 방화벽 규칙 정리

### 4단계: 최종 검증
- [ ] **End-to-End 테스트**
  - 전체 3-tier 아키텍처 동작 확인
  - 각 환경별 독립성 검증
- [ ] **모니터링 및 로깅**
  - 각 서비스별 헬스체크 구현
  - 로그 수집 및 모니터링 설정

## 🐛 현재 알려진 이슈

### MySQL 연결 문제
- **증상**: 백엔드에서 `10.0.0.2:3306` 연결 실패
- **원인**: GCP 방화벽 또는 네트워크 설정 문제 가능성
- **해결 방법**: VPC 내부 방화벽 규칙 재확인 및 네트워크 진단

### VPC 아키텍처 복잡성
- **현재**: management-vpc, moongsan-test-vpc 분리
- **문제**: 각 환경별 VPC 분리 필요
- **해결 방법**: VPC 피어링 및 환경별 VPC 재구성

## 📝 참고사항

### 현재 서버 정보
- **백엔드**: 10.0.0.3 (test-backend)
- **데이터베이스**: 10.0.0.2 (test-database) - MySQL + 백업용 MongoDB
- **AI**: 10.0.0.5 (test-ai) ← **IP 수정됨**
- **공유 점프박스**: 34.47.100.211 (shared-jumpbox, management-vpc의 10.100.0.2)

### 주요 설정 파일
- `ansible/group_vars/test/all.yml` - 최근 수정됨
- `ansible/group_vars/test/vault.yml` - 최근 수정됨
- `ansible/debug-be-deploy.yml` - 최근 수정됨

### 다음 명령어
```bash
# MySQL 연결 테스트
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible
ansible test-backend -i inventories/test.ini -m shell -a "nc -zv 10.0.0.2 3306"

# 백엔드 컨테이너 상태 확인
ansible test-backend -i inventories/test.ini -m shell -a "docker ps -a"

# AI 서비스 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml --tags ai_deploy
```
