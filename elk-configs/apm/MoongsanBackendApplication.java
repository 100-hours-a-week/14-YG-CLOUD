package com.moongsan;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import co.elastic.apm.attach.ElasticApmAttacher;

@SpringBootApplication
public class MoongsanBackendApplication {
    
    static {
        // APM Agent 자동 연결 - 애플리케이션 시작 전에 실행
        ElasticApmAttacher.attach();
    }
    
    public static void main(String[] args) {
        SpringApplication.run(MoongsanBackendApplication.class, args);
    }
}

/* 
위 코드의 동작:
1. static 블록이 먼저 실행되어 APM 에이전트 초기화
2. APM이 자동으로 HTTP 요청, DB 쿼리, 외부 API 호출 등을 추적
3. application.yml의 설정을 자동으로 읽어서 APM 서버에 연결
*/
