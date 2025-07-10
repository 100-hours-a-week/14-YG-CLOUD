#!/bin/bash

# 🔍 ELK 로그 수집 상태 점검 스크립트
# 로그 수집 파이프라인의 각 구성 요소 상태를 종합적으로 점검

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 서버 정보
ELK_SERVER="elk.moongsan.com"
JUMPBOX="34.22.110.81"
AI_SERVER="10.1.0.4"
BACKEND_SERVER="10.1.0.3"

# Elasticsearch 인증 정보 (2025-07-10 업데이트)
ELASTIC_USER="elastic"
ELASTIC_PASSWORD="d*nevMQl9v4Cf6UhyAxW"
BACKEND_SERVER="10.1.0.3"

echo -e "${CYAN}🔍 ELK 로그 수집 상태 종합 점검 시작...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 함수 정의
check_elk_services() {
    echo -e "${BLUE}📋 ELK 스택 서비스 상태 확인...${NC}"
    local services=("elasticsearch" "kibana" "logstash")
    local all_ok=true
    
    for service in "${services[@]}"; do
        local status=$(ssh ${ELK_SERVER} "sudo systemctl is-active $service" 2>/dev/null || echo "inactive")
        if [[ "$status" == "active" ]]; then
            echo -e "   ✅ $service: ${GREEN}정상 실행${NC}"
        else
            echo -e "   ❌ $service: ${RED}중단됨${NC}"
            all_ok=false
        fi
    done
    
    if [[ "$all_ok" == true ]]; then
        echo -e "${GREEN}✅ ELK 스택 모든 서비스 정상${NC}"
        return 0
    else
        echo -e "${RED}❌ ELK 스택 일부 서비스 문제 발생${NC}"
        return 1
    fi
}

check_elasticsearch_connection() {
    echo -e "${BLUE}🔗 Elasticsearch 연결 테스트...${NC}"
    local health=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/_cluster/health'" 2>/dev/null)
    
    if echo "$health" | grep -q '"status":"green"\|"status":"yellow"'; then
        local status=$(echo "$health" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo -e "   ✅ Elasticsearch: ${GREEN}연결 성공${NC} (상태: $status)"
        return 0
    else
        echo -e "   ❌ Elasticsearch: ${RED}연결 실패${NC}"
        return 1
    fi
}

check_logstash_connection() {
    echo -e "${BLUE}🔄 Logstash → Elasticsearch 연결 확인...${NC}"
    local recent_logs=$(ssh ${ELK_SERVER} "sudo journalctl -u logstash --no-pager -n 10" 2>/dev/null)
    
    if echo "$recent_logs" | grep -q "Restored connection to ES instance"; then
        echo -e "   ✅ Logstash: ${GREEN}Elasticsearch 연결 정상${NC}"
        return 0
    elif echo "$recent_logs" | grep -q "Elasticsearch Unreachable\|Connection refused"; then
        echo -e "   ❌ Logstash: ${RED}Elasticsearch 연결 실패${NC}"
        echo -e "   💡 해결 방법: ${YELLOW}sudo systemctl restart logstash${NC}"
        return 1
    else
        echo -e "   ⚠️ Logstash: ${YELLOW}연결 상태 불명확${NC}"
        return 1
    fi
}

check_filebeat_services() {
    echo -e "${BLUE}📡 Filebeat 서비스 상태 확인...${NC}"
    local servers=("$AI_SERVER:AI서버" "$BACKEND_SERVER:Backend서버")
    local all_ok=true
    
    for server_info in "${servers[@]}"; do
        local ip=$(echo $server_info | cut -d':' -f1)
        local name=$(echo $server_info | cut -d':' -f2)
        
        local status=$(ssh -J lsh@${JUMPBOX} ubuntu@${ip} "sudo systemctl is-active filebeat" 2>/dev/null || echo "inactive")
        if [[ "$status" == "active" ]]; then
            echo -e "   ✅ $name ($ip): ${GREEN}Filebeat 정상 실행${NC}"
        else
            echo -e "   ❌ $name ($ip): ${RED}Filebeat 중단됨${NC}"
            all_ok=false
        fi
    done
    
    if [[ "$all_ok" == true ]]; then
        echo -e "${GREEN}✅ 모든 서버의 Filebeat 정상${NC}"
        return 0
    else
        echo -e "${RED}❌ 일부 서버의 Filebeat 문제 발생${NC}"
        return 1
    fi
}

check_service_containers() {
    echo -e "${BLUE}🐳 서비스 컨테이너 상태 확인...${NC}"
    
    # AI 서버 컨테이너 확인
    local ai_containers=$(ssh -J lsh@${JUMPBOX} ubuntu@${AI_SERVER} "docker ps --format '{{.Names}}' | grep moongsan" 2>/dev/null || echo "")
    if [[ -n "$ai_containers" ]]; then
        echo -e "   ✅ AI서버: ${GREEN}$ai_containers 실행 중${NC}"
    else
        echo -e "   ❌ AI서버: ${RED}moongsan 컨테이너 없음${NC}"
    fi
    
    # Backend 서버 컨테이너 확인
    local be_containers=$(ssh -J lsh@${JUMPBOX} ubuntu@${BACKEND_SERVER} "docker ps --format '{{.Names}}' | grep moongsan" 2>/dev/null || echo "")
    if [[ -n "$be_containers" ]]; then
        echo -e "   ✅ Backend서버: ${GREEN}$be_containers 실행 중${NC}"
    else
        echo -e "   ❌ Backend서버: ${RED}moongsan 컨테이너 없음${NC}"
    fi
}

check_log_indices() {
    echo -e "${BLUE}📊 로그 인덱스 및 데이터 확인...${NC}"
    
    # 오늘 날짜 인덱스 확인
    local today=$(date +%Y.%m.%d)
    local index_info=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/_cat/indices/moongsan-logs-${today}?v'" 2>/dev/null)
    
    if echo "$index_info" | grep -q "moongsan-logs-${today}"; then
        local doc_count=$(echo "$index_info" | awk '{print $7}' | tail -n1)
        local size=$(echo "$index_info" | awk '{print $9}' | tail -n1)
        echo -e "   ✅ 오늘 로그 (${today}): ${GREEN}${doc_count}개 문서, ${size} 크기${NC}"
    else
        echo -e "   ❌ 오늘 로그 (${today}): ${RED}인덱스 없음${NC}"
    fi
    
    # 최근 로그 확인
    local recent_log=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/moongsan-logs-${today}/_search?size=1&sort=@timestamp:desc' | jq -r '.hits.hits[]._source | .\"@timestamp\" + \" \" + (.service // \"unknown\") + \" \" + (.server // \"unknown\")'" 2>/dev/null || echo "")
    
    if [[ -n "$recent_log" && "$recent_log" != "null null null" ]]; then
        echo -e "   ✅ 최신 로그: ${GREEN}$recent_log${NC}"
    else
        echo -e "   ❌ 최신 로그: ${RED}데이터 없음${NC}"
    fi
}

check_service_logs() {
    echo -e "${BLUE}🔍 서비스별 로그 수집 현황...${NC}"
    
    local today=$(date +%Y.%m.%d)
    
    # AI 서비스 로그 확인
    local ai_count=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/moongsan-logs-${today}/_count?q=service:ai-moongsan' | jq -r '.count'" 2>/dev/null || echo "0")
    echo -e "   🤖 AI 서비스: ${GREEN}${ai_count}개 로그${NC}"
    
    # Backend 서비스 로그 확인  
    local be_count=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/moongsan-logs-${today}/_count?q=service:backend*' | jq -r '.count'" 2>/dev/null || echo "0")
    echo -e "   🖥️ Backend 서비스: ${GREEN}${be_count}개 로그${NC}"
    
    # 전체 로그 수 확인
    local total_count=$(ssh ${ELK_SERVER} "curl -k -u ${ELASTIC_USER}:${ELASTIC_PASSWORD} -s 'https://localhost:9200/moongsan-logs-${today}/_count' | jq -r '.count'" 2>/dev/null || echo "0")
    echo -e "   📈 전체 로그: ${GREEN}${total_count}개 로그${NC}"
}

provide_recommendations() {
    echo -e "${PURPLE}💡 권장 조치사항${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "${YELLOW}🔧 정기 점검 항목:${NC}"
    echo -e "   • ELK 스택 서비스 상태 (daily)"
    echo -e "   • Filebeat 수집 상태 (daily)"  
    echo -e "   • 로그 인덱스 크기 모니터링 (weekly)"
    echo -e "   • Elasticsearch 디스크 사용량 (weekly)"
    
    echo -e "${YELLOW}⚠️ 문제 발생시 체크 순서:${NC}"
    echo -e "   1. ELK 서비스 상태 확인"
    echo -e "   2. Logstash → Elasticsearch 연결 확인"
    echo -e "   3. Filebeat → Logstash 연결 확인"
    echo -e "   4. 서비스 컨테이너 실행 상태 확인"
    
    echo -e "${YELLOW}🚨 긴급 복구 명령어:${NC}"
    echo -e "   • Logstash 재시작: ${GREEN}sudo systemctl restart logstash${NC}"
    echo -e "   • Filebeat 재시작: ${GREEN}sudo systemctl restart filebeat${NC}"
    echo -e "   • ELK 전체 재시작: ${GREEN}sudo systemctl restart elasticsearch kibana logstash${NC}"
}

# 메인 실행
main() {
    local overall_status=0
    
    # 각 체크 실행
    check_elk_services || overall_status=1
    echo ""
    
    check_elasticsearch_connection || overall_status=1
    echo ""
    
    check_logstash_connection || overall_status=1
    echo ""
    
    check_filebeat_services || overall_status=1
    echo ""
    
    check_service_containers
    echo ""
    
    check_log_indices
    echo ""
    
    check_service_logs
    echo ""
    
    provide_recommendations
    echo ""
    
    # 종합 결과
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ $overall_status -eq 0 ]]; then
        echo -e "${GREEN}🎉 전체 로그 수집 파이프라인 정상 작동 중!${NC}"
        echo -e "${CYAN}📊 대시보드 접속: http://${ELK_SERVER}:5601${NC}"
    else
        echo -e "${RED}⚠️ 일부 구성 요소에서 문제가 발견되었습니다.${NC}"
        echo -e "${YELLOW}위의 권장 조치사항을 참고하여 문제를 해결해주세요.${NC}"
    fi
}

# 스크립트 실행
main "$@"
