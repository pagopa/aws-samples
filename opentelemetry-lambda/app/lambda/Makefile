IMAGE_NAME := s3-bucket-lister-lambda
TAG := latest

build:
	podman build -t $(IMAGE_NAME):$(TAG) --platform linux/amd64 .

run:
	podman run --rm -it \
	-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	-e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) \
	-e AWS_LAMBDA_EXEC_WRAPPER="/opt/otel-instrument" \
	-p 9000:8080 \
	$(IMAGE_NAME):$(TAG)

call:
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
