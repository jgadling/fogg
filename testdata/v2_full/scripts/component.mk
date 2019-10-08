# Auto-generated by fogg. Do not edit
# Make improvements in fogg, so that everyone can benefit.

SELF_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(SELF_DIR)/common.mk

all:
.PHONY: all

setup:
	$(MAKE) -C $(REPO_ROOT) setup
.PHONY: setup

check: lint check-plan
.PHONY: check

fmt: terraform
	@printf "fmt: ";
	@for f in $(TF); do printf .; $(terraform_command) fmt $(TF_ARGS) $$f; done
	@echo
.PHONY: fmt

lint: lint-terraform-fmt lint-tflint
.PHONY: lint

lint-tflint: init
	@printf "tflint: "
ifeq ($(TFLINT_ENABLED),1)
	@tflint || exit $$?;
else
	@echo "disabled"
endif
.PHONY: lint-tflint

lint-terraform-fmt: terraform
	@printf "fmt check: "
	@for f in $(TF); do \
		printf . \
		$(terraform_command) fmt $(TF_ARGS) --check=true --diff=true $$f || exit $$? ; \
	done
	@echo
.PHONY: lint-terraform-fmt

check-auth:
	@aws --profile $(AWS_BACKEND_PROFILE) sts get-caller-identity >/dev/null || echo "AWS AUTH error. This component is configured to use a profile name $(AWS_BACKEND_PROFILE). Please add one to your ~/.aws/config"
	@aws --profile $(AWS_PROVIDER_PROFILE) sts get-caller-identity >/dev/null || echo "AWS AUTH error. This component is configured to use a profile name $(AWS_PROVIDER_PROFILE). Please add one to your ~/.aws/config"
.PHONY: check-auth

ifeq ($(MODE),local)
plan: check-auth init fmt
	@$(terraform_command) plan $(TF_ARGS) -refresh=$(REFRESH_ENABLED) -input=false
else ifeq ($(MODE),atlantis)
plan: check-auth init lint
	@$(terraform_command) plan $(TF_ARGS) -refresh=$(REFRESH_ENABLED) -input=false -out $(PLANFILE) | scenery
else
	@echo "Unknown MODE: $(MODE)"
	@exit -1
endif
.PHONY: plan

ifeq ($(MODE),local)
apply: check-auth init
ifeq ($(ATLANTIS_ENABLED),1)
ifneq ($(FORCE),1)
	@echo "`tput bold`This component is configured to be used with atlantis. If you want to override and apply locally, add FORCE=1.`tput sgr0`"
	exit -1
endif
endif
	@$(terraform_command) apply $(TF_ARGS) -refresh=$(REFRESH_ENABLED) -auto-approve=$(AUTO_APPROVE)
else ifeq ($(MODE),atlantis)
apply: check-auth
	@$(terraform_command) apply $(TF_ARGS) -refresh=$(REFRESH_ENABLED) -auto-approve=true $(PLANFILE)
else
	echo "Unknown mode: $(MODE)"
	exit -1
endif
.PHONY: apply

docs:
	echo
.PHONY: docs

clean:
	-rm -rfv .terraform/modules
	-rm -rfv .terraform/plugins
.PHONY: clean

test:
.PHONY: test

init: terraform check-auth
ifeq ($(MODE),local)
	@$(terraform_command) init -input=false
else ifeq ($(MODE),atlantis)
	@$(terraform_command) init $(TF_ARGS) -input=false
else
	@echo "Unknown MODE: $(MODE)"
	@exit -1
endif
.PHONY: init

check-plan: init check-auth
	@$(terraform_command) plan $(TF_ARGS) -detailed-exitcode; \
	ERR=$$?; \
	if [ $$ERR -eq 0 ] ; then \
		echo "Success"; \
	elif [ $$ERR -eq 1 ] ; then \
		echo "Error in plan execution."; \
		exit 1; \
	elif [ $$ERR -eq 2 ] ; then \
		echo "Diff";  \
	fi
.PHONY: check-plan

run: check-auth
	@$(terraform_command) $(CMD)
.PHONY: run
