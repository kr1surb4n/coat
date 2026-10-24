# Coat test and lint entry points.
#
#   make test                 syntax check, then the automated suite
#   make test TEST_FILTER=paczek   only matching test names
#   make syntax               bash -n on every script
#   make shellcheck           shellcheck at error level; should report nothing
#   make cases                read the manual test checklist
#   make issues               read the list of known issues

SHELL := /bin/bash
SCRIPTS := coat.sh install.sh $(wildcard modules/*.sh)
PAGER := $(shell command -v less 2>/dev/null || command -v more 2>/dev/null || echo cat)

.DEFAULT_GOAL := help
.PHONY: help test check syntax shellcheck lint cases issues

# show the available targets
help:
	@printf '%s\n' \
	  'make test                    syntax check and the automated tests' \
	  'make test TEST_FILTER=word   run only tests whose name contains word' \
	  'make syntax                  bash -n on coat.sh, install.sh and modules' \
	  'make shellcheck              shellcheck at error level; should report nothing' \
	  'make lint                    syntax + shellcheck' \
	  'make cases                   open docs/test-cases.md' \
	  'make issues                  open docs/issues.md'

# the normal entry point: never deploy, only use throwaway folders
test: syntax
	@TEST_FILTER="$(TEST_FILTER)" bash tests/run.sh

# alias for test
check: test

# parse every script before running anything
syntax:
	@bash -n $(SCRIPTS)
	@printf 'syntax ok (%s files)\n' "$(words $(SCRIPTS))"

# static analysis; the scripts should be clean
shellcheck:
	@shellcheck -S error $(SCRIPTS)

# both checks; both should pass
lint: syntax shellcheck

# the readable checklist for the parts a machine cannot judge
cases:
	@$(PAGER) docs/test-cases.md

# what is broken, why, and what to do about it
issues:
	@$(PAGER) docs/issues.md
