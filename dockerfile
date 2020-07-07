###########
# BUILDER #
###########
FROM lambci/lambda:build-go1.x as builder

# set work directory
WORKDIR /app

# set work directory
COPY . /app

# install deps
RUN go mod download

# build
RUN GOOS=linux GOARCH=amd64 go build -o ./bin/service ./src

RUN zip -j service.zip ./bin/service

#########
# Final #
#########
FROM alpine:latest

ENV TERRAFORM_VERSION 0.12.28

# set work directory
RUN apk add --no-cache curl
WORKDIR /usr/src/app

# set work directory
COPY . /usr/src/app/

# copy binary from builder
COPY --from=builder /app/service.zip .

# download terraform
RUN cd /usr/local/bin && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# init terraform
RUN terraform init -input=false

# run terraform build
CMD ["sh", "./scripts/build_terraform.sh"]