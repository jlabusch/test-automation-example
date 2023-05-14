FROM node:lts-buster

RUN mkdir -p /opt/paysauce-tests

WORKDIR /opt/paysauce-tests

COPY . /opt/paysauce-tests

RUN npm install

ENTRYPOINT ["./bin/run_tests.sh"]
