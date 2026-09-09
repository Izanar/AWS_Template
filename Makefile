# ImageTestEnv - common task runner
#
# Usage:
#   make validate        Validate Terraform sources, Ansible, Kubernetes and Shell
#   make fmt             Format Terraform code
#   make init [ENV=..]   Run `terragrunt init` for one environment
#   make plan  [ENV=..]  Run `terragrunt plan`
#   make apply [ENV=..]  Run `terragrunt apply` (creates billable resources!)
#   make destroy [ENV=..] Run `terragrunt destroy`
#   make output [ENV=..] Show terraform outputs
#
# ENV selects the Terragrunt environment directory under envs/ (default: ec2-dev).
# Supported values: ec2-dev eks-fargate-dev eks-ec2-s3-dev local-wsl-dev
#
# Requires: terraform >= 1.9, terragrunt >= 0.68, and either aws CLI (cloud
# scenarios) or nothing (local-wsl-dev). Use `make install-tools` to get them
# into ~/.local/bin and ~/venvs/tools (Python 3.11+).

SHELL := /usr/bin/env bash
ENV   ?= ec2-dev
ENV_DIR := envs/$(ENV)
SRC_DIRS := $(wildcard src/*)
TERRAFORM ?= terraform
TERRAGRUNT ?= terragrunt
PYVENV := $(HOME)/venvs/tools/bin

.PHONY: help validate validate-tf validate-ansible validate-k8s validate-shell \
        fmt init plan apply destroy output install-tools lint precommit test

help:
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | sed 's/:.*//' | sort -u | sed 's/^/  make /'

install-tools:
	@echo "Installing Terraform, Terragrunt and Python tooling into ~/.local/bin and ~/venvs/tools"
	mkdir -p $(HOME)/.local/bin
	@command -v $(TERRAFORM) >/dev/null || { \
	  TF_VER=$$(curl -fsSL https://api.github.com/repos/hashicorp/terraform/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p'); \
	  curl -fsSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/$${TF_VER}/terraform_$${TF_VER}_linux_amd64.zip"; \
	  python3 -c "import zipfile; zipfile.ZipFile(r'/tmp/terraform.zip').extractall(r'$(HOME)/.local/bin')"; \
	  chmod +x $(HOME)/.local/bin/terraform; }
	@command -v $(TERRAGRUNT) >/dev/null || { \
	  TG_VER=$$(curl -fsSL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p'); \
	  curl -fsSL -o $(HOME)/.local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v$${TG_VER}/terragrunt_linux_amd64"; \
	  chmod +x $(HOME)/.local/bin/terragrunt; }
	@python3 -m venv --without-pip $(PYVENV)/.. 2>/dev/null || true
	$(PYVENV)/python -m pip install -q ansible-core ansible-lint yamllint pre-commit shellcheck-py

init:
	$(TERRAGRUNT) --working-dir $(ENV_DIR) init

plan:
	$(TERRAGRUNT) --working-dir $(ENV_DIR) plan -input=false

apply:
	$(TERRAGRUNT) --working-dir $(ENV_DIR) apply -auto-approve

destroy:
	$(TERRAGRUNT) --working-dir $(ENV_DIR) destroy -auto-approve

output:
	$(TERRAGRUNT) --working-dir $(ENV_DIR) output

fmt:
	$(TERRAFORM) fmt -recursive src

validate-tf:
	@for d in $(SRC_DIRS); do \
	  echo "==> $$d"; \
	  (cd $$d && $(TERRAFORM) init -backend=false -input=false -no-color >/dev/null && $(TERRAFORM) validate -no-color) || exit 1; \
	done
	$(TERRAFORM) fmt -check -recursive src

validate-ansible:
	@command -v $(PYVENV)/ansible-playbook >/dev/null || $(PYVENV)/pip install -q ansible-core
	ANSIBLE_ROLES_PATH=ansible/roles $(PYVENV)/ansible-playbook --syntax-check -i localhost, ansible/playbooks/ec2.yml
	ANSIBLE_ROLES_PATH=ansible/roles $(PYVENV)/ansible-playbook --syntax-check ansible/playbooks/eks-deploy.yml
	ANSIBLE_ROLES_PATH=ansible/roles $(PYVENV)/ansible-lint ansible/

validate-k8s:
	@$(PYVENV)/python -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" kubernetes/base/*.yaml
	$(PYVENV)/yamllint kubernetes/ .github/workflows/

validate-shell:
	@command -v $(PYVENV)/shellcheck >/dev/null || $(PYVENV)/pip install -q shellcheck-py
	$(PYVENV)/shellcheck scripts/*.sh

validate: validate-tf validate-ansible validate-k8s validate-shell

precommit:
	$(PYVENV)/pre-commit run --all-files

lint: precommit validate

test: validate lint

docs:
	@echo "Run: python3 -m http.server -d docs 8080"
