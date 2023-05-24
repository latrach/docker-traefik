#===================================================================================================
# 🎨 VARIABLES
#===================================================================================================
DOCKER_CONTAINER_NAME = $(shell cat .env | grep APP_CONTAINER_NAME | cut -d'=' -f2)
DOCKER_COMPOSE_FILE = docker-compose-local.yml
PHPQA = jakzal/phpqa:php8.1
DOCKER-COMMAND = $(or $c, bash)

#===================================================================================================
#  🆘  HELP
#===================================================================================================
help: ## Show this help.
	@echo "Makefile : Docker, composer, git, console, npm, phpqa - said@latrach.net - 2023"
	@echo "Usage: make [target]"
	@echo "Targets:"
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

#===================================================================================================
#  🐋  DOCKER
#===================================================================================================
docker: docker-up ## Execute docker command, Usage: make docker c="command"
	@echo "==============================================================================="
	@echo "🐋 Vous etes dans le contenaire $(DOCKER_CONTAINER_NAME)"
	@echo "==============================================================================="
	docker exec -it $(DOCKER_CONTAINER_NAME) bash
.PHONY: docker

docker-exec: docker-up ## Docker exec, Usage: make docker-exec c="command"
	docker exec -it $(DOCKER_CONTAINER_NAME) $(DOCKER-COMMAND)
.PHONY: docker-exec

docker-up: ## Start docker containers.
	docker compose -f ../docker-traefik/$(DOCKER_COMPOSE_FILE) up -d
	docker compose -f ../docker-databases/$(DOCKER_COMPOSE_FILE) up -d
	docker compose -f ../docker-tunnelssh/$(DOCKER_COMPOSE_FILE) up -d
	docker compose -f ../nesws-sf4/$(DOCKER_COMPOSE_FILE) up -d
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
.PHONY: docker-up

docker-stop: ## Stop docker containers.
	docker compose -f $(DOCKER_COMPOSE_FILE) stop
.PHONY: docker-stop

#===================================================================================================
#  📦  COMPOSER
#===================================================================================================
composer: docker-up ## Ecexute composer commande, Usage: make composer c="command"
	docker exec -it $(DOCKER_CONTAINER_NAME) composer $(c)
.PHONY: composer

composer-install: ## Install composer dependencies.
	docker exec -it $(DOCKER_CONTAINER_NAME) composer install
.PHONY: composer-install

composer-update: ## Update composer dependencies.
	docker exec -it $(DOCKER_CONTAINER_NAME) composer update --with-all-dependencies
.PHONY: composer-update

composer-validate: ## Validate composer.json file.
	docker exec -it $(DOCKER_CONTAINER_NAME) composer validate
.PHONY: composer-validate

composer-validate-deep: ## Validate composer.json and composer.lock files in strict mode.
	docker exec -it $(DOCKER_CONTAINER_NAME) composer validate --strict --check-lock
.PHONY: composer-validate-deep

#===================================================================================================
#  ⚡  GIT
#===================================================================================================
git-push: ## Git push develop and recette. Usage: make git-push m="commit message"
	git fetch --all
	git add .
	git commit -m "$(m)"
	git push
	git checkout recette
	git merge --ff --no-edit develop
	git push
	git checkout develop
.PHONY: git-push

#===================================================================================================
#  🔳  CONSOLE
#===================================================================================================
console: docker-up ## Execute symfony console commande, Usage: make console c="command"
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console $(c)
.PHONY: console

console-cc: ## Cache clear.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console c:c
.PHONY: console-cc

console-dump-env: ## Dump env.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console debug:dotenv
.PHONY: console-dump-env

console-dump-env-container: ## Dump Env container.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console debug:container --env-vars
.PHONY: console-dump-env-container

console-dump-routes: ## Dump routes.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console debug:router
.PHONY: console-dump-routes

#===================================================================================================
#  📦  NPM
#===================================================================================================
npm: docker-up ## Execute npm command, Usage: make npm c="command"
	docker exec -it $(DOCKER_CONTAINER_NAME) npm $(c)
.PHONY: npm

npm-add: ## Add npm dependencies, Usage: make npm-add p="package-name"
	docker exec -it $(DOCKER_CONTAINER_NAME) npm install $(p)
.PHONY: npm-add

npm-set: ## Install npm dependencies.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm set strict-ssl false
	docker exec -it $(DOCKER_CONTAINER_NAME) npm install caniuse-lite browserslist --save-dev
	docker exec -it $(DOCKER_CONTAINER_NAME) npm audit fix
.PHONY: npm-set

npm-install: npm-set ## Install npm dependencies.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm install --force
.PHONY: npm-install

npm-update: npm-set ## Update npm dependencies.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm update
.PHONY: npm-update

npm-prod: npm-set ## Build assets for prod mode.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm run build
.PHONY: npm-prod

npm-dev: npm-set ## Build assets in dev mode.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm run dev
.PHONY: npm-dev

npm-watch: npm-set ## Watch assets.
	docker exec -it $(DOCKER_CONTAINER_NAME) npm run watch
.PHONY: npm-watch

#===================================================================================================
#  🐛  PHPQA
#===================================================================================================
qa-cs-fixer-dry-run: ## Run php-cs-fixer in dry-run mode.
	docker run --init --rm -v $(PWD):/project -w /project $(PHPQA) php-cs-fixer fix ./src --rules=@Symfony --verbose --dry-run
.PHONY: qa-cs-fixer-dry-run

qa-cs-fixer: ## Run php-cs-fixer.
	docker run --init --rm -v $(PWD):/project -w /project $(PHPQA) php-cs-fixer fix ./src --rules=@Symfony --verbose
.PHONY: qa-cs-fixer

qa-phpstan: ## Run phpstan.
	docker run --init --rm -v $(PWD):/project -w /project $(PHPQA) phpstan analyse ./src --level=5
.PHONY: qa-phpstan

qa-security-checker: ## Run security-checker.
	symfony security:check
.PHONY: qa-security-checker

qa-phpcpd: ## Run phpcpd (copy/paste detector).
	docker run --init --rm -v $(PWD):/project -w /project $(PHPQA) phpcpd ./src
.PHONY: qa-phpcpd

qa-php-metrics: ## Run php-metrics.
	docker run --init --rm -v $(PWD):/project -w /project $(PHPQA) phpmetrics --report-html=var/phpmetrics ./src
.PHONY: qa-php-metrics

qa-lint-twigs: ## Lint twig files.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console lint:twig ./templates
.PHONY: qa-lint-twigs

qa-lint-yaml: ## Lint yaml files.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console lint:yaml ./config
.PHONY: qa-lint-yaml

qa-lint-container: ## Lint container.
	docker exec -it $(DOCKER_CONTAINER_NAME) php bin/console lint:container
.PHONY: qa-lint-container

qa-audit: ## Run composer audit.
	docker exec -it $(DOCKER_CONTAINER_NAME) composer audit
.PHONY: qa-audit

#===================================================================================================
#  🔎  TESTS
#===================================================================================================
tests: ## Run tests.
	docker exec -it -e APP_ENV=test $(DOCKER_CONTAINER_NAME) php bin/phpunit --testdox
.PHONY: tests

tests-coverage: ## Run tests with coverage.
	docker exec -it -e APP_ENV=test $(DOCKER_CONTAINER_NAME) php bin/phpunit --coverage-html var/coverage
.PHONY: tests-coverage

#===================================================================================================
#  🧵  OTHERS SCRIPTS
#===================================================================================================
sh-recursive-cp-makefile: ## Copy common Makefile to all webapp projects recursively.
	./sh-recursive-cp-makefile
.PHONY: sh-recursive-cp-makefile

sh-recursive-rm-file: ## Remove file recursively, Usage: make sh-recursive-rm-file f="file"
	./sh-recursive-rm-file $(f)
.PHONY: sh-recursive-rm-file

sh-recursive-git-push: ## Git push recursively, Usage: make sh-recursive-git-push m="commit message"
	./sh-recursive-git-push "$(m)"
.PHONY: sh-recursive-git-push