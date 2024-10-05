########################################
### cleanup
########################################
.PHONY: clean

clean:
	@find .localstack -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
	@rm -rf authz/build
	@rm -rf lambda/dist

########################################
### build
########################################
.PHONY: build build-authz build-lambda

build: build-authz build-lambda
build-authz:
	@mkdir -p ./authz/build
	@go build -o ./authz/build/authz ./authz/main.go
build-lambda:
	@pushd lambda; \
	  pnpm install; \
	  pnpm build; \
	popd

########################################
### docker
########################################
.PHONY: docker-build docker-build-authz docker-build-lambda docker-push docker-push-authz docker-push-lambda

docker-build: docker-build-authz docker-build-lambda
docker-build-authz:
	@docker compose build authz
docker-build-lambda:
	@docker compose build lambda

docker-push: docker-build
	@docker compose push lambda
	@docker compose push authz
docker-push-lambda: docker-build-lambda
	@docker compose push lambda
docker-push-authz: docker-build-authz
	@docker compose push authz

docker-run: docker-build
	@docker compose up authz
	@docker compose up lambda
docker-run-authz: docker-build-authz
	@docker compose up authz
docker-run-lambda: docker-build-lambda
	@docker compose up lambda

########################################
### localstack
########################################
.PHONY: localstack localstack-lambda

localstack-up:
	@docker compose up localstack

localstack-lambda: docker-push-lambda
	@docker compose exec localstack /tmp/lambda/create.sh
localstack-lambda-get-config:
	@docker compose exec localstack /tmp/lambda/get-config.sh

localstack-cloudfront:
	@docker compose exec localstack /tmp/cloudfront/update.sh
localstack-cloudfront-get-config:
	@docker compose exec localstack /tmp/cloudfront/get-config.sh
