FROM python:3.11

WORKDIR /

COPY ./requirements.txt /requirements.txt
RUN apt-get update && apt-get install -y build-essential libpq-dev \
    && python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r /requirements.txt


COPY ./ /

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
