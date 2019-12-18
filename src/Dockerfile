FROM python:3.7-alpine3.9

RUN pip3.7 install awscli pyhamcrest

ADD ./ /backup-ssm

RUN cd  /backup-ssm/ && python3.7 /backup-ssm/setup.py install

WORKDIR /
