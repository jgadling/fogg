# Auto-generated by fogg. Do not edit
# Make improvements in fogg, so that everyone can benefit.

SELF_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(SELF_DIR)/common.mk

all:
.PHONY: all

setup:
	$(MAKE) -C $(REPO_ROOT) setup

check: lint check-plan
.PHONY: check

fmt: terraform
	@printf "running fmt: ";
	@for f in $(TF); do printf .; terraform fmt $$f; done
	@echo
.PHONY: fmt

lint: terraform-validate lint-terraform-fmt lint-tflint
.PHONY: lint

lint-tflint: init
	@if (( $$TFLINT_ENABLED )); then \
		tflint || exit $$?; \
	fi
.PHONY: lint-tflint

terraform-validate: terraform init
	@$(terraform_command) validate -check-variables=true
.PHONY: terraform-validate

lint-terraform-fmt: terraform
	@for f in $(TF); do \
		printf . \
		$(terraform_command) fmt --check=true --diff=true $$f || exit $$? ; \
	done
.PHONY: lint-terraform-fmt

ifeq ($(MODE),local)
plan: init fmt
	@$(terraform_command) plan
else ifeq ($(MODE),atlantis)
plan: init lint
	@$(terraform_command) plan -input=false -no-color -out $PLANFILE | scenery
else
	@echo "Unknown MODE: $(MODE)"
	@exit -1
endif
.PHONY: plan

ifeq ($(MODE),local)
apply: init
ifeq ($(ATLANTIS_ENABLED),1)
ifneq ($(FORCE),1)
	@echo "`tput bold`This component is configured to be used with atlantis. If you want to override and apply locally, add FORCE=1.`tput sgr0`"
	exit -1
endif
endif
	$(terraform_command) apply -auto-approve=$(AUTO_APPROVE)
else ifeq ($(MODE),atlantis)
apply:
	$(terraform_command) apply -auto-approve=true $PLANFILE
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

init: terraform
ifeq ($(MODE),local)
	@$(terraform_command) init -input=false
else ifeq ($(MODE),atlantis)
	@t=`mktemp $(REPO_ROOT)/.fogg/tmp/init.XXXX` && \
	echo $$t && \
	$(terraform_command) init -input=false -no-color > $$t 2>&1 || (a=$$?; echo $$a && cat $$t; exit $$a)
else
	@echo "Unknown MODE: $(MODE)" \
	@exit -1
endif
.PHONY: init

check-plan: init
	@$(terraform_command) plan -detailed-exitcode; \
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

run:
	terraform $(CMD)
.PHONY: run
