# 1단계: 빌드용 Python 이미지 사용
FROM python:3.11-slim AS builder

# 작업 디렉토리 설정
WORKDIR /app

# 시스템 패키지 설치 및 pip 업데이트
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

# requirements 복사 및 설치
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --user -r requirements.txt

# 앱 코드 복사
COPY . .

# 2단계: 실행 이미지
FROM python:3.11-slim

# 작업 디렉토리
WORKDIR /app

# 로깅 경로 생성 및 권한 설정
RUN mkdir -p /var/log/moongsan && chown -R 1000:1000 /var/log/moongsan

# requirements 복사 및 설치
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# 앱 코드 복사
COPY . .

# ENTRYPOINT로 로그 출력
ENTRYPOINT ["bash", "-c", "/root/.local/bin/uvicorn app:app --host 0.0.0.0 --port 8100 --log-level debug --access-log | tee -a /var/log/moongsan/ai_moongsan.log"]