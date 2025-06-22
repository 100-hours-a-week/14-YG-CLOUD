# Redis Master Mode 배포 역할

이 Ansible 역할은 Redis를 **마스터 모드**로 배포하여 READONLY 에러를 방지합니다.

## 문제 해결

### 문제 상황
- Redis 인스턴스가 replica(slave) 모드로 설정되어 쓰기 명령어가 차단됨
- Spring 애플리케이션에서 Redis Lock 설정 시 READONLY 에러 발생
- 수동으로 `REPLICAOF NO ONE` 명령 실행 필요

### 해결 방법
1. **템플릿 기반 설정**: `redis.conf.j2`로 마스터 모드 설정 강제
2. **자동 마스터 전환**: 컨테이너 시작 후 자동으로 마스터 상태 확인 및 전환
3. **상태 검증**: 배포 완료 후 마스터 상태 최종 확인

## 주요 기능

### 1. 마스터 모드 보장
- `replicaof` 설정 제거로 기본 마스터 모드 시작
- 컨테이너 시작 후 `REPLICAOF NO ONE` 자동 실행 (필요시)

### 2. 템플릿 기반 설정
```jinja2
# 마스터 모드 강제 설정
replica-read-only no
replica-serve-stale-data yes
```

### 3. 자동 상태 검증
- Redis 연결 테스트
- 마스터 상태 확인
- 필요시 자동 모드 전환
- 최종 상태 검증 및 출력

## 사용법

### 기본 배포
```bash
ansible-playbook -i test.ini test-redis.yml --limit backend
```

### 전체 백엔드 서비스와 함께 배포
```bash
ansible-playbook -i test.ini playbooks/main.yml --tags be_deploy --limit backend
```

## 설정 변수

`group_vars/test/all.yml`에서 Redis 설정:

```yaml
db:
  redis:
    image: "redis:7.2-alpine"
    container_name: "redis-{{ service_name }}"
    host: "redis-{{ service_name }}"
    port: "{{ app_ports.redis }}"
    mode: "master"  # 마스터 모드 명시
    
    # 성능 설정
    timeout: 0
    tcp_keepalive: 300
    maxmemory: "256mb"
    maxmemory_policy: "allkeys-lru"
    maxclients: 10000
    databases: 16
    
    # 로깅 설정
    loglevel: "notice"
    
    container:
      data_dir: "/var/lib/redis-data"
      config_dir: "/etc/redis"
      config_file: "/etc/redis/redis.conf"
```

## 검증 명령

### Redis 상태 확인
```bash
ansible test-backend -i test.ini -m shell -a "docker exec redis-moongsan redis-cli INFO replication" --become
```

### 쓰기 테스트
```bash
ansible test-backend -i test.ini -m shell -a 'docker exec redis-moongsan redis-cli SET test_key "test_value"' --become
```

### 읽기 테스트  
```bash
ansible test-backend -i test.ini -m shell -a 'docker exec redis-moongsan redis-cli GET test_key' --become
```

## 배포 결과

성공적인 배포 시 다음과 같은 출력을 확인할 수 있습니다:

```
✅ Redis is running as: MASTER
🔧 Redis Final Status:
- role:master
- connected_slaves:0
- master_failover_state:no-failover
```

## 파일 구조

```
roles/redis/
├── tasks/main.yml          # 배포 태스크
├── templates/redis.conf.j2 # Redis 설정 템플릿
└── README.md              # 이 문서
```

## 특징

- ✅ **완전 자동화**: 수동 개입 없이 마스터 모드 보장
- ✅ **재배포 안전**: 기존 컨테이너 정리 후 재시작
- ✅ **상태 검증**: 배포 후 자동 상태 확인
- ✅ **오류 방지**: READONLY 에러 완전 제거
- ✅ **템플릿 기반**: 환경별 설정 유연성 제공
