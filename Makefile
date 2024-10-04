########################################
### cleanup
########################################
.PHONY: clean

clean:
	@find .localstack -mindepth 1 -maxdepth 1 ! -name 'bootstrap' ! -name 'lib' -exec rm -rf {} +
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

docker-push: docker-build docker-push-authz docker-push-lambda
docker-push-authz:
	@docker compose push authz
docker-push-lambda:
	@docker compose push lambda

########################################
### localstack
########################################
.PHONY: localstack localstack-lambda

localstack-up:
	@mkdir -p .localstack/lib
	@cp -f ./tools/scripts/logs.sh ./.localstack/lib/logs.sh
	@docker compose up localstack
localstack-lambda:
	@cp -f ./tools/scripts/localstack-lambda-create.sh ./.localstack/lib/create-lambda.sh
	@docker compose exec localstack /var/lib/localstack/lib/create-lambda.sh
