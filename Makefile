AWS_DEFAULT_REGION ?= eu-east-1
PYTHON ?= python3
BEHAVE ?= behave
KEYFILE ?=.anslk_random_testkey

LIBFILES := $(shell find backup_cloud_ssm -name '*.py')
START := $(shell date -u +'%Y-%m-%dT%H%M%S' )

all: lint test

# pytest-mocked is much faster than non-mocked which is slower even than
# the functional tests so run it first, then behave then ffinally the
# full pytest tests so that failures are detected early where possible.
test: develop pytest-mocked behave pytest 

behave:
	behave --tags ~@future

pytest-mocked:
	MOCK_AWS=true pytest

pytest:
	pytest

wip: develop
	behave --wip

lint:
	pre-commit install --install-hooks
	pre-commit run -a


# develop is needed to install scripts that are called during testing 
develop: .develop.makestamp

.develop.makestamp: setup.py backup_cloud_ssm/aws_ssm_cli.py $(LIBFILES)
	$(PYTHON) setup.py install --force
	$(PYTHON) setup.py develop
	touch $@

.PHONY: all test behave pytest-mocked pytest wip lint develop


build-docker: ## Build docker image for backup-ssm
	docker build -t backup-ssm -f src/Dockerfile .

run-docker-backup: check-secret-env ## Run backup command in docker - check-secret-env-backup

	mkdir -p ssm-backup-$(START)

	touch ssm-backup-$(START)/ssm-backup-$(START).txt

	docker run -it --rm -v $(SOURCE_ABSOLUTE_PATH):/backup-ssm -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) -e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) -e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) backup-ssm:latest aws-ssm-backup > ssm-backup-$(START)/ssm-backup-$(START).txt

run-docker-restore: check-restore-env ## Run restore command in docker
	docker run -it --rm -v $(SOURCE_ABSOLUTE_PATH):/tmp/ssm_to_restore.txt -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) -e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) -e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) backup-ssm:latest ash -c "aws-ssm-backup --restore < /tmp/ssm_to_restore.txt"

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check-secret-env: ## Checks to make sure AWS environment variables used by backup-ssm are set
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID is undefined)
endif

ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY is undefined)
endif

ifndef AWS_DEFAULT_REGION
	$(error AWS_DEFAULT_REGION is undefined)
endif


check-restore-env: check-secret-env ## Check to make sure source file has been set & exists
ifndef SOURCE_ABSOLUTE_PATH
	$(error SOURCE_ABSOLUTE_PATH is undefined)
endif

	@# Check if source exists locally on host machine
	@if [ ! -f "$(SOURCE_ABSOLUTE_PATH)" ]; then echo -e "\n\nSource '$(SOURCE_ABSOLUTE_PATH)' does not exist.\n"; exit 1 ; fi