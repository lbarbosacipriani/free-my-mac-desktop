FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV MAC_SAFE_CLEANER_HOME=/host-home
ENV MAC_SAFE_CLEANER_QUARANTINE=/data/quarantine
ENV MAC_SAFE_CLEANER_REPORTS=/data/reports
ENV HOST=127.0.0.1
ENV PORT=8080

WORKDIR /app

COPY pyproject.toml README.md ./
COPY src ./src
COPY run_cleaner.py ./

RUN pip install --no-cache-dir .

EXPOSE 8080

CMD ["python", "-m", "mac_safe_cleaner.web"]
