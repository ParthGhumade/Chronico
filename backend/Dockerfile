FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system runtime dependencies:
# - ffmpeg: audio inspection and chunking for Sarvam STT
# - libcairo2, libpango-1.0-0, libpangoft2-1.0-0: WeasyPrint PDF layout & rendering
# - fonts-noto-core, fonts-deva, fontconfig: Marathi Devanagari typography
# - curl: healthcheck queries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libcairo2 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libffi-dev \
    shared-mime-info \
    fonts-noto-core \
    fonts-deva \
    fontconfig \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy backend source code
COPY . /app/backend

# Ensure runtime directories exist
RUN mkdir -p /app/backend/uploads /app/backend/generated_reports

# Set permissions on entrypoint script
RUN chmod +x /app/backend/start.sh

# Expose API port (default: 8000)
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/backend/start.sh"]
CMD ["api"]
