# Scripts 디렉토리 - Script-Free 아키텍처

> **🎯 철학**: 스크립트 의존성을 최소화하고 순수한 Terraform/Ansible 명령어 기반 배포를 권장합니다.

## 📁 현재 구조

```
scripts/
├── cleanup-resources.sh        # 리소스 정리 도구 (필수)
├── generate-wireguard-keys.sh  # WireGuard 키 생성 유틸리티 (필수)
└── archive/                    # 아카이브된 기존 스크립트들
    ├── bootstrap.sh            # → docs/script-free-deployment-guide.md로 대체
    ├── deploy.sh              # → 수동 배포 가이드로 대체
    ├── deploy-frontend.sh     # → GCS 업로드 명령어로 대체
    ├── setup-terraform-backend.sh  # → Bootstrap 가이드로 대체
    └── cleanup-all.sh         # → cleanup-resources.sh로 개선
```

## 🚀 권장 배포 방식

### 1️⃣ 최고 권장: Script-Free 배포
```bash
# 📖 가이드 문서 참조
cat docs/script-free-deployment-guide.md

# 또는 온라인에서 보기
open docs/script-free-deployment-guide.md
```

**장점:**
- ✅ 완전한 투명성 (모든 명령어가 명시적)
- ✅ 디버깅 용이성
- ✅ Terraform/Ansible 베스트 프랙티스 학습
- ✅ 스크립트 실행 실패 위험 제거

### 2️⃣ 필수 도구들

#### 🧹 리소스 정리 도구
```bash
# 사용법 확인
./scripts/cleanup-resources.sh

# 테스트 환경만 정리
./scripts/cleanup-resources.sh test --env-only

# 전체 정리 (Bootstrap 포함)
./scripts/cleanup-resources.sh test

# 정리 계획만 확인 (Dry Run)
./scripts/cleanup-resources.sh test --dry-run
```

#### 🔐 WireGuard 키 생성
```bash
# WireGuard 키 생성
./scripts/generate-wireguard-keys.sh

# 생성된 키 확인
ls -la wireguard-keys/
```

## 🗂️ 아카이브된 스크립트들

아카이브된 스크립트들은 `archive/` 디렉토리에 보존되어 있습니다. 이들은 더 이상 권장되지 않으며, 대신 다음과 같이 대체되었습니다:

| 기존 스크립트 | 대체 방법 |
|-------------|-----------|
| `bootstrap.sh` | [Script-Free 가이드](../docs/script-free-deployment-guide.md#1단계-bootstrap-리소스-생성) |
| `deploy.sh` | [Manual 배포 가이드](../docs/terraform-manual-deployment.md) |
| `deploy-frontend.sh` | GCS 업로드 명령어 직접 사용 |
| `setup-terraform-backend.sh` | Bootstrap 가이드의 수동 절차 |
| `cleanup-all.sh` | `cleanup-resources.sh` (개선된 버전) |

## 🎓 왜 Script-Free인가?

### ❌ 기존 스크립트 방식의 문제점
- 복잡한 bash 로직으로 인한 디버깅 어려움
- 숨겨진 환경 변수 의존성
- 스크립트 실행 중 실패 시 중간 상태 파악 어려움
- Terraform/Ansible 명령어가 스크립트에 감춰짐

### ✅ Script-Free 방식의 장점
- **투명성**: 모든 명령어가 문서에 명시적으로 기록
- **안정성**: 스크립트 실행 실패 위험 제거
- **학습성**: Terraform/Ansible 베스트 프랙티스 직접 학습
- **재현성**: 동일한 명령어로 동일한 결과 보장
- **디버깅**: 각 단계별로 상태 확인 가능

## 📚 관련 문서

- [🎯 Script-Free 배포 가이드](../docs/script-free-deployment-guide.md) - 권장 방법
- [📖 Terraform 수동 배포](../docs/terraform-manual-deployment.md) - 기존 수동 가이드  
- [🔧 프로젝트 구조 분석](../docs/terraform-structure-analysis.md) - 아키텍처 분석

---

> 💡 **팁**: 처음 사용하시는 분들은 Script-Free 가이드를 차근차근 따라하면서 인프라를 이해해보세요. 스크립트에 의존하지 않고 직접 명령어를 실행함으로써 더 깊은 이해를 얻을 수 있습니다.
