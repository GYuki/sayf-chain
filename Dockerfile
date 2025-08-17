FROM golang:1.23-alpine AS build-env

# Install minimum necessary dependencies
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev
RUN apk add --no-cache $PACKAGES

# Set working directory for the build
WORKDIR /go/src/github.com/sayf/sayf-chain

# optimization: if go.sum didn't change, docker will use cached image
COPY go.mod go.sum ./
COPY collections/go.mod collections/go.sum ./collections/
COPY store/go.mod store/go.sum ./store/
COPY log/go.mod log/go.sum ./log/

RUN go mod download

# Add source files
COPY . .

# Dockerfile Cross-Compilation Guide
# https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide
ARG TARGETOS TARGETARCH

# install simapp, remove packages
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH make build

# Use alpine:3 as a base image
FROM alpine:3

EXPOSE 26656 26657 1317 9090
# Run simd by default, omit entrypoint to ease using container with simcli
CMD ["simd"]
STOPSIGNAL SIGTERM
WORKDIR /root

# Install minimum necessary dependencies
RUN apk add --no-cache curl make bash jq sed

# Copy over binaries from the build-env
COPY --from=build-env /go/src/github.com/sayf/sayf-chain/build/simd /usr/bin/simd
