FROM python:3.8-slim
WORKDIR /app
COPY . /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 3443

CMD ["python", "app.py"]
