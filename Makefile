########################################
### cleanup
########################################
.PHONY: clean

clean:
	@docker stop $$(docker ps -a -q) || true
	@docker rm $$(docker ps -a -q) || true
	@find .localstack -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
	@rm -rf authz/src/build
	@rm -rf lambda/dist

########################################
### build
########################################
.PHONY: build build-authz build-lambda

build: build-authz build-lambda
build-authz:
	@mkdir -p ./authz/src/build
	@go build -o ./authz/src/build/authz ./authz/src/main.go
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
.PHONY: localstack localstack-lambda

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
