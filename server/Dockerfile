FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV HOST=0.0.0.0 PORT=8787
EXPOSE 8787
CMD ["python", "app.py"]
