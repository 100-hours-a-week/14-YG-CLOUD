# 1단계: 빌드 이미지
FROM python:3.11-slim AS builder

WORKDIR /app

# 빌드에 필요한 패키지 설치
RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

# requirements 복사 및 설치
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# 앱 소스 복사
COPY . .

# 2단계: 실행 이미지
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# 로그 디렉토리 생성
RUN mkdir -p /var/log/moongsan && chown -R 1000:1000 /var/log/moongsan

# 필요 경로 복사 및 PATH 설정
# COPY --from=builder /root/.local /root/.local
# RUN chmod -R +x /root/.local

# ENV PATH=/root/.local/bin:$PATH

# 앱 소스 복사
COPY . .

# # 유저 변경 (보안상 root 대신 비root 사용자 권장)
# USER 1000

# 로그를 tee로 파일에 저장하며 동시에 콘솔 출력
ENTRYPOINT ["bash", "-c", "/root/.local/bin/uvicorn app:app --host 0.0.0.0 --port 8100 --log-level debug --access-log | tee -a /var/log/moongsan/ai_moongsan.log"]