BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: help git-commit git-push git-pull

help: ## Affiche cette aide
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<cible>\033[0m [m=<message>]\n\n"} \
	  /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

.DEFAULT_GOAL := help

git-commit: ## Commit + push docker-traefik + .ai-brain  (usage: make git-commit m="message")
	git add -A
	git commit -m "$(m)"
	git push origin $(BRANCH)
	git push github $(BRANCH)
	git -C .ai-brain add -A
	git -C .ai-brain diff --cached --quiet || git -C .ai-brain commit -m "$(m)"
	git -C .ai-brain push origin main

git-push: ## Push origin (GitLab) + github
	git push origin $(BRANCH)
	git push github $(BRANCH)

git-pull: ## Pull github + .ai-brain
	git pull github $(BRANCH)
	git -C .ai-brain pull origin main
