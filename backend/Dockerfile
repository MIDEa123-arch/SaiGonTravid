FROM python:3.9-slim

WORKDIR /app

# Cài thêm libpq-dev cho Postgres và g++ cho một số thư viện C
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Thêm cờ --reload để nó tự động load lại code khi ông giáo nhấn Save file
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]