from fastapi import FastAPI, HTTPException
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM
import elasticapm
from elasticapm import capture_span
import os

# APM 클라이언트 설정
apm_config = {
    'SERVICE_NAME': 'moongsan-ai',
    'SERVICE_VERSION': '1.0.0',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production',
    
    # 데이터 캡처 설정
    'CAPTURE_BODY': 'all',
    'CAPTURE_HEADERS': True,
    
    # 샘플링 설정 (1.0 = 100% 추적)
    'TRANSACTION_SAMPLE_RATE': 1.0,
    
    # APM 활성화
    'ENABLE': True,
    
    # 로그 연동
    'CENTRAL_CONFIG': False,
    'LOG_LEVEL': 'info',
    
    # 성능 설정
    'STACK_TRACE_LIMIT': 50,
    'SPAN_FRAMES_MIN_DURATION': 5,  # ms
}

# APM 클라이언트 생성
apm = make_apm_client(apm_config)

# FastAPI 앱 생성
app = FastAPI(
    title="Moongsan AI API",
    description="AI 추론 및 모델 서비스",
    version="1.0.0"
)

# APM 미들웨어 추가 - 이것이 핵심!
app.add_middleware(ElasticAPM, client=apm)

# 예시 API 엔드포인트
@app.get("/")
async def root():
    """루트 엔드포인트"""
    return {"message": "Moongsan AI API", "status": "running"}

@app.post("/ai/predict")
async def predict(request_data: dict):
    """AI 모델 추론 API"""
    
    # 커스텀 스팬으로 세부 추적
    with capture_span("input_validation"):
        if not request_data or 'data' not in request_data:
            raise HTTPException(status_code=400, detail="Invalid input data")
    
    # 모델 추론 부분을 별도 스팬으로 추적
    with capture_span("ai_model_inference") as span:
        # 커스텀 태그 추가
        span.tag(model_version="v1.2.3")
        span.tag(request_size=len(str(request_data)))
        
        try:
            # 실제 AI 모델 호출 (예시)
            result = await process_ai_inference(request_data['data'])
            
            # 성공 메트릭 추가
            elasticapm.tag(inference_status="success")
            elasticapm.tag(result_confidence=result.get('confidence', 0))
            
            return {
                "status": "success",
                "result": result,
                "model_version": "v1.2.3"
            }
            
        except Exception as e:
            # 에러 자동 캡처
            elasticapm.capture_exception()
            elasticapm.tag(inference_status="failed")
            elasticapm.tag(error_type=type(e).__name__)
            
            raise HTTPException(status_code=500, detail=f"AI inference failed: {str(e)}")

async def process_ai_inference(data):
    """AI 모델 추론 로직 (예시)"""
    
    # 데이터 전처리 스팬
    with capture_span("data_preprocessing"):
        # 전처리 로직
        processed_data = data
    
    # 모델 실행 스팬
    with capture_span("model_execution"):
        # 실제 모델 실행 (예시)
        import time
        import random
        
        # 가짜 추론 시간 (실제로는 모델 실행 시간)
        await asyncio.sleep(random.uniform(0.1, 0.5))
        
        result = {
            "prediction": "example_result",
            "confidence": random.uniform(0.8, 0.99),
            "processing_time": "0.2s"
        }
    
    return result

@app.get("/health")
async def health_check():
    """헬스체크 API"""
    
    # 커스텀 메트릭 추가
    elasticapm.tag(health_check="ok")
    
    return {
        "status": "healthy",
        "service": "moongsan-ai",
        "timestamp": "2025-07-03T02:00:00Z"
    }

# 애플리케이션 시작 이벤트
@app.on_event("startup")
async def startup_event():
    """앱 시작시 APM 초기화 로그"""
    print("🚀 Moongsan AI API 시작됨")
    print(f"📊 APM 서버: {apm_config['SERVER_URL']}")
    print(f"🎯 서비스명: {apm_config['SERVICE_NAME']}")

# 애플리케이션 종료 이벤트
@app.on_event("shutdown")
async def shutdown_event():
    """앱 종료시 정리"""
    print("🛑 Moongsan AI API 종료됨")

if __name__ == "__main__":
    import uvicorn
    import asyncio
    
    # 개발 환경에서 실행할 때
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )

"""
APM이 자동으로 추적하는 항목들:

1. HTTP 요청/응답:
   - 요청 URL, 메소드, 헤더
   - 응답 상태코드, 시간
   - 요청/응답 크기

2. 데이터베이스 쿼리:
   - SQL 쿼리문, 실행시간
   - 데이터베이스 연결 정보

3. 외부 API 호출:
   - HTTP 클라이언트 요청
   - 응답시간, 상태코드

4. 예외/에러:
   - 스택트레이스 자동 캡처
   - 에러 발생 위치, 시간

5. 시스템 메트릭:
   - CPU, 메모리 사용률
   - 프로세스 정보
"""
