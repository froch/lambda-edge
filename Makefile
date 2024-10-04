.PHONY: clean build build-authz build-lambda

########################################
### cleanup
########################################

clean:
	@find .localstack -mindepth 1 -maxdepth 1 ! -name 'bootstrap' -exec rm -rf {} +
	@rm -rf authz/build
	@rm -rf lambda/dist

########################################
### build
########################################

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

docker:
	@docker compose build authz
	@docker compose build lambda
