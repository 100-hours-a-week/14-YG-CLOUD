# 1단계: 빌드 이미지
FROM python:3.11 AS builder

WORKDIR /app
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --upgrade pip && \ 
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge
COPY . /app

# 2단계: 실행 이미지
FROM python:3.11

WORKDIR /app
RUN apt-get update && apt-get install -y gcc && \ 
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /app /app
RUN mkdir -p /var/log/moongsan && chown -R 1000:1000 /var/log/moongsan
ENTRYPOINT ["bash", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8100 --log-level debug --access-log | tee -a /var/log/moongsan/ai_moongsan.log"]