# 1단계: builder
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# 2단계: runtime
FROM python:3.11
WORKDIR /app

# 복사: site-packages + bin (uvicorn 등)
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

ENTRYPOINT ["bash", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8100"]