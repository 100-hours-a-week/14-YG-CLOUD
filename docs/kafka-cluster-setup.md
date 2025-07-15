# Kafka + Zookeeper 클러스터 구성

## 📋 개요
단일 서버에서 Docker Compose를 사용하여 Kafka 3대, Zookeeper 3대 클러스터를 안전하게 배포

## 🏗️ 아키텍처

### Zookeeper 클러스터
| 컨테이너 | 포트 | 역할 |
|---------|------|------|
| zookeeper-1 | 2181 | 클러스터 리더 가능 |
| zookeeper-2 | 2182 | 클러스터 멤버 |
| zookeeper-3 | 2183 | 클러스터 멤버 |

### Kafka 브로커 클러스터
| 컨테이너 | 내부 포트 | 외부 포트 | 역할 |
|---------|----------|----------|------|
| kafka-1 | 9092 | 19092 | 브로커 #1 |
| kafka-2 | 9092 | 19093 | 브로커 #2 |
| kafka-3 | 9092 | 19094 | 브로커 #3 |

### 관리 도구
| 서비스 | 포트 | 용도 |
|--------|------|------|
| kafka-ui | 8089 | 웹 기반 Kafka 관리 UI |

## 🐳 Docker 구성

### 이미지
- **Zookeeper**: `bitnami/zookeeper:3.9`
- **Kafka**: `bitnami/kafka:3.6`
- **Kafka UI**: `provectuslabs/kafka-ui:latest`

### 네트워크
- **moongsan-net**: 기존 BE/AI/DB 서비스와 동일한 외부 네트워크 사용

### 볼륨 (데이터 지속성)
```
zookeeper-1-data, zookeeper-2-data, zookeeper-3-data
kafka-1-data, kafka-2-data, kafka-3-data
```

## 📡 연결 정보

### BE 서비스에서 접근 (내부 통신)
```
KAFKA_BOOTSTRAP_SERVERS=kafka-1:9092,kafka-2:9092,kafka-3:9092
```

### 외부에서 접근 (개발/테스트)
```
KAFKA_BOOTSTRAP_SERVERS=10.178.0.18:19092,19093,19094
```

### 관리 UI 접근
```
Kafka UI: http://10.178.0.18:8089
```

## 🚀 배포 방법

### Ansible 자동화 배포
```bash
cd /Users/lsh/Documents/GitHub/14-YG-CLOUD/ansible
ansible-playbook playbook.yml --tags kafka -i inventory.ini -l dev
```

### 수동 배포 (필요시)
```bash
cd /home/ubuntu/kafka-cluster
docker-compose -f docker-compose.kafka.yml up -d
```

## 📊 기본 토픽

자동 생성되는 토픽:
- `user-events` (6 파티션, 복제본 3개)
- `order-events` (6 파티션, 복제본 3개)  
- `notification-events` (3 파티션, 복제본 3개)

## 🔧 관리 명령어

### 헬스체크
```bash
./kafka_health_check.sh
```

### 토픽 조회
```bash
docker exec kafka-1 kafka-topics.sh --list --bootstrap-server kafka-1:9092
```

### 로그 확인
```bash
docker-compose -f /home/ubuntu/kafka-cluster/docker-compose.kafka.yml logs -f
```

### 컨테이너 상태 확인
```bash
docker ps --filter "name=kafka" --filter "name=zookeeper"
```

## ⚠️ 주의사항

- 기존 서비스(BE, AI, DB 등)에 영향 없음
- moongsan-net 네트워크를 공유하여 내부 통신 가능
- BE 환경변수에 Kafka 설정이 자동으로 추가됨
- 고가용성을 위해 복제본 3개로 구성
- 자동 토픽 생성 활성화

## 📈 리소스 사용량

| 컨테이너 | 메모리 사용량 (예상) |
|---------|------------------|
| Kafka (각각) | ~360MB |
| Zookeeper (각각) | ~110MB |
| Kafka UI | ~270MB |
| **총합** | **~1.5GB** |

## 🔗 관련 파일

- **Docker Compose**: `/home/ubuntu/kafka-cluster/docker-compose.kafka.yml`
- **헬스체크 스크립트**: `/home/ubuntu/kafka_health_check.sh`
- **Ansible 역할**: `ansible/roles/kafka_cluster/`
- **BE 환경변수**: `ansible/roles/be_deploy/templates/env.prod.j2`
