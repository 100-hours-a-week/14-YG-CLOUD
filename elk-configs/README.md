# ELK Stack Configuration Files
## 사용자 계정

### Elasticsearch 접속
- **관리자**: elastic / d*nevMQl9v4Cf6UhyAxW (2025-07-10 업데이트)렉토리에는 3-Tier 아키텍처용 ELK (Elasticsearch, Logstash, Kibana) 스택의 설정 파일들이 저장되어 있습니다.

## 디렉토리 구조

```
elk-configs/
├── filebeat/           # Filebeat 설정 파일들
│   ├── filebeat-backend.yml     # Backend 서버용 Filebeat 설정
│   ├── filebeat-ai.yml          # AI 서버용 Filebeat 설정
│   └── filebeat-database.yml    # Database 서버용 Filebeat 설정
├── logstash/           # Logstash 파이프라인 설정
│   └── beats-input.conf         # Beats 입력 및 Elasticsearch 출력 설정
├── kibana/             # Kibana 설정
│   └── kibana.yml              # Kibana 메인 설정 파일
└── README.md           # 이 파일
```

## 서버 정보

### ELK Stack 서버
- **Host**: elk.moongsan.com (10.100.0.4)
- **Elasticsearch**: https://elk.moongsan.com:9200
- **Kibana**: http://elk.moongsan.com:5601
- **Logstash**: elk.moongsan.com:5044

### 3-Tier 서버들
- **Backend**: 10.1.0.3 (prod-backend)
- **AI**: 10.1.0.4 (prod-ai)  
- **Database**: 10.1.0.2 (prod-database)

## 사용자 계정

### Elasticsearch
- **관리자**: elastic / d*nevMQl9v4Cf6UhyAxW (2025-07-10 업데이트)
- **Kibana 시스템**: kibana_system / kibana_password123

### Kibana 웹 접속
- **URL**: http://elk.moongsan.com:5601
- **관리자 계정**: moongsan_admin / moongsan123 (추천)
- **또는 기본 계정**: elastic / d*nevMQl9v4Cf6UhyAxW (2025-07-10 업데이트)

## 로그 수집 현황

- **인덱스 패턴**: `moongsan-logs-YYYY.MM.DD`
- **수집되는 로그 타입**:
  - system: 시스템 로그 (syslog, auth.log, daemon.log)
  - application: 애플리케이션 로그 (Spring Boot, FastAPI)
  - docker: Docker 컨테이너 로그
  - database: MySQL/MariaDB 로그

## 설치 및 배포 명령어

### Filebeat 설정 배포
```bash
# Backend 서버
scp -i ~/.ssh/lsh-study-key filebeat/filebeat-backend.yml ubuntu@10.1.0.3:/tmp/
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.3 "sudo cp /tmp/filebeat-backend.yml /etc/filebeat/filebeat.yml && sudo systemctl restart filebeat"

# AI 서버  
scp -i ~/.ssh/lsh-study-key filebeat/filebeat-ai.yml ubuntu@10.1.0.4:/tmp/
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.4 "sudo cp /tmp/filebeat-ai.yml /etc/filebeat/filebeat.yml && sudo systemctl restart filebeat"

# Database 서버
scp -i ~/.ssh/lsh-study-key filebeat/filebeat-database.yml ubuntu@10.1.0.2:/tmp/
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.2 "sudo cp /tmp/filebeat-database.yml /etc/filebeat/filebeat.yml && sudo systemctl restart filebeat"
```

### Logstash 설정 배포
```bash
scp -i ~/.ssh/lsh-study-key logstash/beats-input.conf lsh@elk.moongsan.com:/tmp/
ssh -i ~/.ssh/lsh-study-key lsh@elk.moongsan.com "sudo cp /tmp/beats-input.conf /etc/logstash/conf.d/ && sudo systemctl restart logstash"
```

### Kibana 설정 배포
```bash
scp -i ~/.ssh/lsh-study-key kibana/kibana.yml lsh@elk.moongsan.com:/tmp/
ssh -i ~/.ssh/lsh-study-key lsh@elk.moongsan.com "sudo cp /tmp/kibana.yml /etc/kibana/ && sudo systemctl restart kibana"
```

## 상태 확인 명령어

### 서비스 상태 확인
```bash
# ELK 서버에서
ssh -i ~/.ssh/lsh-study-key lsh@elk.moongsan.com "sudo systemctl status elasticsearch logstash kibana"

# 각 서버에서 Filebeat 상태 확인
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.3 "sudo systemctl status filebeat"
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.4 "sudo systemctl status filebeat"  
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.2 "sudo systemctl status filebeat"
```

### 로그 수집 현황 확인
```bash
# 전체 로그 수
curl -k -u elastic:d*nevMQl9v4Cf6UhyAxW 'https://elk.moongsan.com:9200/moongsan-logs-*/_search?size=0' | jq '.hits.total.value'

# 서버별 로그 수
curl -k -u elastic:d*nevMQl9v4Cf6UhyAxW 'https://elk.moongsan.com:9200/moongsan-logs-*/_search?size=0&q=server:backend' | jq '.hits.total.value'
curl -k -u elastic:d*nevMQl9v4Cf6UhyAxW 'https://elk.moongsan.com:9200/moongsan-logs-*/_search?size=0&q=server:ai' | jq '.hits.total.value'
curl -k -u elastic:d*nevMQl9v4Cf6UhyAxW 'https://elk.moongsan.com:9200/moongsan-logs-*/_search?size=0&q=server:database' | jq '.hits.total.value'
```

## 구축 완료 날짜
- 2025년 7월 3일 ELK 중앙 로깅 시스템 구축 완료
