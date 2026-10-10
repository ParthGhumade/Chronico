FROM python:3.11-slim

WORKDIR /app

# Install system dependencies required for psycopg2 and WeasyPrint
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    libcairo2 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libffi-dev \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
# Ensure psycopg2-binary is installed for PostgreSQL support
RUN pip install --no-cache-dir -r requirements.txt psycopg2-binary

# Copy backend source code
COPY . /app/backend/

# Expose port 8000 for FastAPI
EXPOSE 8000

# Default command to run FastAPI via uvicorn
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
