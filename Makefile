.PHONY: dev

PROJECT?=kiroshi

dev:
	docker-compose run $(PROJECT) /bin/bash
