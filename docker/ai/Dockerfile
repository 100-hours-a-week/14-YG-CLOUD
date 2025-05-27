# 1단계: 빌드 이미지
FROM python:3.11 AS builder

WORKDIR /app

# 빌드에 필요한 패키지 설치
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

# requirements 복사 및 설치
COPY v1/requirements.txt .
RUN pip install --upgrade pip && \ 
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# 앱 소스 복사
COPY v1 /app
WORKDIR /app

# 2단계: 실행 이미지
FROM python:3.11

WORKDIR /app

RUN apt-get update && apt-get install -y gcc && \ 
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# 실행 이미지에서 아래만 복사
COPY --from=builder /app /app

# 로그 디렉토리 생성
RUN mkdir -p /var/log/moongsan && chown -R 1000:1000 /var/log/moongsan

# 로그를 tee로 파일에 저장하며 동시에 콘솔 출력
ENTRYPOINT ["bash", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8100 --log-level debug --access-log | tee -a /var/log/moongsan/ai_moongsan.log"]