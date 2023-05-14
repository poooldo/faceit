# build stage
FROM golang:alpine AS build-env
RUN apk --no-cache add build-base git gcc
ADD devops-challenge/test-app/ /src
WORKDIR /src
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build ./cmd/ops-test-app

# final stage
FROM alpine
WORKDIR /app
COPY --from=build-env /src/ops-test-app /app/
ENTRYPOINT ./ops-test-app
