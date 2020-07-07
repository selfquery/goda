
###########
# BUILDER #
###########

# pull official base image
FROM alpine:latest as builder

ENV TERRAFORM_VERSION 0.12.28

# set work directory
RUN apk add --no-cache git make musl-dev go zip curl
WORKDIR /usr/src/app

# set environment variables
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

# set work directory
COPY . /usr/src/app/

# install deps
RUN go get "github.com/aws/aws-lambda-go/lambda"
RUN go get "github.com/aws/aws-lambda-go/events"

# build
RUN GOOS=linux GOARCH=amd64 go build -o ./bin/service ./src

# zip
RUN zip service.zip ./bin/service

RUN cd /usr/local/bin && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN terraform init -input=false

CMD ["sh", "build.sh"]