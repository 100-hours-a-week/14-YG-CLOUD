# 📚 14-YG-CLOUD 문서 가이드

> **체계적으로 정리된 5개 핵심 문서**로 14-YG-CLOUD 프로젝트의 모든 것을 다룹니다.

## 🎯 핵심 문서 (5개)

### 📋 [`README.md`](./README.md) 
**문서 인덱스 및 프로젝트 개요** - 지금 보고 있는 이 문서

### 🏗️ [`infrastructure-complete-guide.md`](./infrastructure-complete-guide.md) 
**인프라 완전 가이드** - 아키텍처 설계부터 최적화 과정, 최종 결과까지 모든 것
- Part 1: 아키텍처 설계 (3-Tier 구조, 네트워크 설계)
- Part 2: 최적화 여정 (Jump Box, AI 서버, 로드밸런서, 디스크 최적화)
- Part 3: 최종 결과 (18% 비용 절약, $227.77/월)
- Part 4: 현재 아키텍처 상태 (완성된 시스템 상세)

### 🔧 [`deployment-guide.md`](./deployment-guide.md) 
**스크립트 없는 배포 가이드** - 순수 Terraform/Ansible 명령어로 투명한 배포
- Bootstrap 리소스 생성
- 환경별 인프라 배포  
- 애플리케이션 배포
- WireGuard VPN 설정

### 🔐 [`security-guide.md`](./security-guide.md) 
**통합 보안 가이드** - 모든 보안 설정을 한 곳에
- Part 1: Git 보안 (민감한 정보 보호)
- Part 2: Ansible Vault 보안 (암호화된 설정 관리)
- Part 3: WireGuard VPN 설정 (안전한 네트워크 접근)
- Part 4: 종합 보안 체크리스트

### 🔧 [`troubleshooting-guide.md`](./troubleshooting-guide.md) 
**문제해결 가이드** - 모든 문제상황과 해결방법
- Terraform 문제해결
- Ansible 문제해결  
- WireGuard VPN 문제해결
- GCP 리소스 문제해결
- 네트워크 연결 문제해결
- 긴급 상황 대응

## 📦 Archive (과거 분석 자료)

상세한 분석 과정과 레거시 문서들은 [`archive/`](./archive/) 폴더에 보관되어 있습니다:

```
archive/
├── 2024-06-optimization/     # 최적화 과정 상세 분석들
├── deployment-guides/        # 중복되었던 배포 가이드들  
├── project-reports/          # 프로젝트 진행 상황 보고서들
├── security-guides/          # 개별 보안 가이드들
└── legacy-analysis/          # 초기 분석 및 고민 과정들
```

## 🚀 빠른 시작 가이드

### **1. 처음 사용하는 경우**
1. [`infrastructure-complete-guide.md`](./infrastructure-complete-guide.md) - 전체 이해
2. [`deployment-guide.md`](./deployment-guide.md) - 실제 배포
3. [`security-guide.md`](./security-guide.md) - 보안 설정

### **2. 문제가 발생한 경우**  
1. [`troubleshooting-guide.md`](./troubleshooting-guide.md) - 문제해결
2. 해당 영역별 가이드 참고

### **3. 상세 분석이 필요한 경우**
1. [`archive/`](./archive/) 폴더의 세부 분석 문서들 참고

## 💡 문서 특징

- ✅ **5개 고정 구조**: 더 이상 문서가 늘어나지 않음
- ✅ **내용 손실 없음**: 모든 과거 분석 내용이 보존됨  
- ✅ **쉬운 접근**: 필요한 정보를 빠르게 찾을 수 있음
- ✅ **체계적 정리**: 주제별로 논리적으로 구성됨

---

> 💬 **사용 팁**: 각 문서는 독립적으로 읽을 수 있지만, 전체적인 이해를 위해서는 `infrastructure-complete-guide.md`부터 시작하는 것을 추천합니다.