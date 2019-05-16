FROM python:3.7
MAINTAINER Dmitry Gamanenko

WORKDIR /usr/src/app

RUN apt-get update -y && \
	apt-get install -y --no-install-recommends python-setuptools && \
	rm -rf /var/lib/apt/lists/*

COPY . .
RUN pip install --upgrade pip && pip install -r requirements.txt