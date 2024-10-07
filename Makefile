########################################
### cleanup
########################################
.PHONY: clean

clean:
	@docker stop $$(docker ps -a -q) || true
	@docker rm $$(docker ps -a -q) || true
	@find .localstack -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
	@rm -rf authz/build
	@rm -rf lambda/dist
	@cd authz/src && go clean -testcache

########################################
### linters
########################################
.PHONY: lint-authz fmt-authz check-golangci-lint check-gofmt check-goimports

lint-authz: check-golangci-lint
	@pushd ./authz > /dev/null 2>&1; \
	  golangci-lint run --timeout 5m; \
	popd > /dev/null 2>&1;
fmt-authz: check-goimports check-gofmt
	@pushd ./authz > /dev/null 2>&1; \
	  find . -name '*.go' -type f -not -path "*.git*" | xargs gofmt -d -w -s; \
	  find . -name '*.go' -type f -not -path "*.git*" | xargs goimports -w -local github.com/froch/lambda-edge/authz; \
	popd > /dev/null 2>&1;

check-golangci-lint:
	@command -v golangci-lint >/dev/null 2>&1 || { \
		echo "golangci-lint is not installed. Installing..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	}
check-gofmt:
	@command -v gofmt >/dev/null 2>&1 || { \
		echo "gofmt is not installed. Installing..."; \
		go install golang.org/x/tools/cmd/gofmt@latest; \
	}
check-goimports:
	@command -v goimports >/dev/null 2>&1 || { \
		echo "goimports is not installed. Installing..."; \
		go install golang.org/x/tools/cmd/goimports@latest; \
	}

########################################
### tests
########################################
.PHONY: test-authz test-lambda

test-authz:
	@pushd ./authz > /dev/null 2>&1;  \
	  go clean -testcache; \
	  go test -v ./...; \
	popd > /dev/null 2>&1;
test-lambda:
	@pushd lambda > /dev/null 2>&1; \
	  pnpm install; \
	  pnpm test; \
	popd > /dev/null 2>&1;

########################################
### build
########################################
.PHONY: build build-authz build-lambda

build: build-authz build-lambda
build-authz:
	@mkdir -p ./authz/build
	@pushd ./authz > /dev/null 2>&1; \
	  go build -o ./build/authz ./main.go; \
	popd > /dev/null 2>&1;
build-lambda:
	@pushd lambda; \
	  pnpm install; \
	  pnpm build; \
	popd

install-authz:
	@pushd ./authz > /dev/null 2>&1; \
	  go mod verify; \
	  go install -mod=readonly; \
	popd > /dev/null 2>&1;

########################################
### docker
########################################
.PHONY: docker-build docker-build-authz docker-build-lambda docker-push docker-push-authz docker-push-lambda

docker-build: docker-build-authz docker-build-lambda
docker-envsubst:
	@ cp docker-compose.yaml docker-compose.yaml.bak; \
 	envsubst < docker-compose.yaml.bak > docker-compose.yaml
docker-build-authz: docker-envsubst
	@ docker compose build authz; \
	mv -f docker-compose.yaml.bak docker-compose.yaml
docker-build-lambda: docker-envsubst
	@docker compose build lambda; \
	mv -f docker-compose.yaml.bak docker-compose.yaml
docker-push: docker-build
	@docker compose push lambda
	@docker compose push authz
docker-push-lambda: docker-build-lambda docker-envsubst
	@docker compose push lambda
	mv -f docker-compose.yaml.bak docker-compose.yaml
docker-push-authz: docker-build-authz docker-envsubst
	@docker compose push authz
	mv -f docker-compose.yaml.bak docker-compose.yaml

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
.PHONY: localstack-up localstack-lambda localstack-lambda-get-config localstack-lambda-get-iam localstack-cloudfront localstack-cloudfront-get-config localstack-cloudfront-get-origin-request-policy

localstack-up:
	@docker compose up localstack

localstack-lambda: docker-push-lambda
	@docker compose exec localstack /tmp/lambda/create.sh
localstack-lambda-get-config:
	@docker compose exec localstack /tmp/lambda/get-config.sh
localstack-lambda-get-iam:
	@docker compose exec localstack /tmp/lambda/get-iam.sh

localstack-cloudfront:
	@docker compose exec localstack /tmp/cloudfront/update.sh
localstack-cloudfront-get-config:
	@docker compose exec localstack /tmp/cloudfront/get-config.sh
localstack-cloudfront-get-origin-request-policy:
	@docker compose exec localstack /tmp/cloudfront/get-origin-request-policy.sh

########################################
### k8s
########################################
.PHONY: k8s-deploy-authz #k8s-deploy-lambda

k8s-deploy-authz:
	@ \
	pushd ./authz/k8s > /dev/null 2>&1; \
	  cp skaffold.yaml skaffold.yaml.bak; \
	  cp deployment.yaml deployment.yaml.bak; \
	  envsubst < skaffold.yaml.bak > skaffold.yaml; \
	  envsubst < deployment.yaml.bak > deployment.yaml; \
	  skaffold deploy; \
	  mv -f skaffold.yaml.bak skaffold.yaml; \
	  mv -f deployment.yaml.bak deployment.yaml; \
	popd > /dev/null 2>&1;
