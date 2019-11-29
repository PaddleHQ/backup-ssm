FROM python:3.7.5-stretch


RUN pip3.7 install awscli pyhamcrest

ADD ./ /backup-ssm

RUN cd  /backup-ssm/ && python3.7 /backup-ssm/setup.py install
# RUN python -m pip install -r /backup-ssm/requirements.txt
# RUN python -m pip install gpg==1.8

WORKDIR /