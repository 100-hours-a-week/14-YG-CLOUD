package com.moongsan.config;

import co.elastic.apm.api.ElasticApm;
import co.elastic.apm.api.Transaction;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@Configuration
public class ApmConfiguration implements WebMvcConfigurer {
    
    // 커스텀 인터셉터로 추가 메트릭 수집 (선택사항)
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new ApmInterceptor());
    }
    
    public static class ApmInterceptor implements HandlerInterceptor {
        
        @Override
        public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
            // 커스텀 태그 추가
            Transaction transaction = ElasticApm.currentTransaction();
            if (transaction != null) {
                transaction.addTag("user-agent", request.getHeader("User-Agent"));
                transaction.addTag("request-ip", request.getRemoteAddr());
            }
            return true;
        }
    }
}

/* 
추가로 사용할 수 있는 APM API:

// 커스텀 트랜잭션 생성
Transaction transaction = ElasticApm.startTransaction();
transaction.setName("custom-operation");
transaction.setType("background");
try {
    // 비즈니스 로직
} finally {
    transaction.end();
}

// 커스텀 스팬 생성 (세부 추적)
Span span = ElasticApm.currentTransaction().startSpan();
span.setName("database-query");
span.setType("db");
try {
    // DB 쿼리 실행
} finally {
    span.end();
}

// 에러 수동 캡처
ElasticApm.captureException(new Exception("Custom error"));

// 커스텀 메트릭 추가
ElasticApm.currentTransaction().addTag("order-amount", "1000");
*/
