FROM alpine:3.7

RUN apk update && apk add --no-cache openssh bash openssl curl

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

WORKDIR /src
COPY make_cfg.sh /src/
RUN chmod +x /src/make_cfg.sh

RUN mkdir /data
VOLUME [ "/data" ]

ENTRYPOINT ["./make_cfg.sh"]