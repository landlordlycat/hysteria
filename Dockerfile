FROM golang:alpine AS builder

LABEL maintainer="mritd <mritd@linux.com>"

# GOPROXY is disabled by default, use:
# docker build --build-arg GOPROXY="https://goproxy.io" ...
# to enable GOPROXY.
ARG GOPROXY=""

ENV GOPROXY ${GOPROXY}

COPY . /go/src/github.com/tobyxdd/hysteria

WORKDIR /go/src/github.com/tobyxdd/hysteria/cmd

RUN set -ex \
    && export VERSION=$(git describe --tags) \
    && export COMMIT=$(git rev-parse HEAD) \
    && export TIMESTAMP=$(date "+%F %T") \
    && go build -o /go/bin/hysteria -ldflags \
        "-w -s -X 'main.appVersion=${VERSION}' \
        -X 'main.appCommit=${COMMIT}' \
        -X 'main.appDate=${TIMESTAMP}'"

# multi-stage builds to create the final image
FROM alpine AS dist

LABEL maintainer="mritd <mritd@linux.com>"

# bash is used for debugging, tzdata is used to add timezone information.
# Install ca-certificates to ensure no CA certificate errors.
#
# Do not try to add the "--no-cache" option when there are multiple "apk"
# commands, this will cause the build process to become very slow.
RUN set -ex \
    && apk upgrade \
    && apk add bash tzdata ca-certificates \
    && rm -rf /var/cache/apk/*

COPY --from=builder /go/bin/hysteria /usr/local/bin/hysteria

ENTRYPOINT ["hysteria"]
