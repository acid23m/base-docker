#
# Project tools.
# Documentation for makefile: https://www.gnu.org/software/make/manual/make.html
#
# Usage:
# make - shows help with available commands
# make [command] - runs specific command
#

PROJECT_DIR=${PWD}
APP_DIR=$(PROJECT_DIR)/app
CONF_DIR=$(PROJECT_DIR)/conf
CONF_CERTS_DIR=$(CONF_DIR)/certs
DB_BACKUP_DIR=$(PROJECT_DIR)/db/backup

SHELL=/bin/bash
#.SHELLFLAGS = -a

DEFAULT_GOAL := help
.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


# ensures of existing .env file
$(PROJECT_DIR)/.env: $(PROJECT_DIR)/.env.example
	@if [[ -f $@ ]]; then \
		echo "The $(<F) file has changed. Please check your $(@F) file."; \
		touch $@; \
		exit 1; \
	else \
		echo "Please configure project by modifing $(@F) file: nano $(@F)"; \
		cp -a $< $@; \
		chmod 640 $@; \
		exit 1; \
	fi

include $(PROJECT_DIR)/.env

CONTAINER_FPM=${COMPOSE_PROJECT_NAME}_fpm
CONTAINER_DB=${COMPOSE_PROJECT_NAME}_db

define SET_PERMISSIONS=
sudo chown -R ${OS_USER_NAME}:www-data $(PROJECT_DIR)
sudo find $(PROJECT_DIR) -type d -exec chmod 750 {} \;
sudo find $(PROJECT_DIR) -type f -exec chmod 640 {} \;
sudo find $(CONF_DIR) -type d -exec chmod 755 {} \;
sudo find $(CONF_DIR) -type f -exec chmod 644 {} \;
sudo chmod u+x $(PROJECT_DIR)/bin/*
sudo $(PROJECT_DIR)/bin/appperm -c $(CONF_DIR)/appperm/appperm.yml -u ${OS_USER_NAME} $(APP_DIR)
endef

define PING_APP=
# ping site homepage
if curl \
	--connect-timeout 60 \
	--http1.1 \
	--insecure \
	--keepalive-time 60 \
	--location \
	--silent \
	--show-error \
	--head \
	--url "http://localhost:${SITE_PORT}" &> /dev/null; \
then\
	echo "Site is Active.";\
else\
	echo "Site is NOT Active.";\
fi
# ping admin panel
if curl \
	--connect-timeout 60 \
	--http1.1 \
	--insecure \
	--keepalive-time 60 \
	--location \
	--silent \
	--show-error \
	--head \
	--url "http://localhost:${SITE_PORT}/admin" &> /dev/null; \
then\
	echo "Admin panel is Active.";\
else\
	echo "Admin panel is NOT Active.";\
fi
# ping api
if curl \
	--connect-timeout 60 \
	--http1.1 \
	--insecure \
	--keepalive-time 60 \
	--location \
	--silent \
	--show-error \
	--head \
	--url "http://localhost:${SITE_PORT}/api" &> /dev/null; \
then\
	echo "Api is Active.";\
else\
	echo "Api is NOT Active.";\
fi
endef

define COMPOSER_DEPS=
docker exec -i \
	-w /app \
	$(CONTAINER_FPM) \
	composer self-update
docker exec -i \
	$(CONTAINER_FPM) \
	composer global update --prefer-dist --no-dev --no-suggest --optimize-autoloader
if [[ "${APP_MODE}" == "prod" ]]; then \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		composer update --prefer-dist --no-dev --no-suggest --optimize-autoloader; \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		composer dump-autoload --optimize --no-dev --classmap-authoritative; \
else \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		composer update --prefer-dist --optimize-autoloader -vvv; \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		composer dump-autoload --optimize -vvv; \
fi
docker exec -i \
	-w /app \
	$(CONTAINER_FPM) \
	composer clear-cache
endef

define INIT_YII=
# initiates framework
if [[ "${APP_MODE}" == "prod" ]]; then \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./init --env=Production --overwrite=All; \
else \
	docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./init --env=Development --overwrite=All; \
fi
# applies db migrations
docker exec -i \
	-w /app \
	$(CONTAINER_FPM) \
	php ./yii migrate --interactive=0
endef


##@ Docker containers

$(CONF_CERTS_DIR)/dhparam.pem:
	@openssl dhparam -out $@ -dsaparam 4096

$(CONF_CERTS_DIR)/cert.%: $(CONF_CERTS_DIR)/dhparam.pem
	@openssl req -x509 -nodes -newkey rsa:4096 -days 36500 \
		-keyout $(CONF_CERTS_DIR)/cert.key \
		-out $(CONF_CERTS_DIR)/cert.crt \
		-subj "/C=RU/ST=RU/L=Internet/O=$(hostname -s)/CN=${SITE_DOMAIN}"


.PHONY: start
start: $(PROJECT_DIR)/.env $(CONF_CERTS_DIR)/dhparam.pem $(CONF_CERTS_DIR)/cert.% ## Runs project.
	# defines database and runs containers
	@if [[ "${APP_MODE}" == "prod" ]]; then \
		(export DB_NAME=${DB_NAME_PROD} && docker-compose -p ${COMPOSE_PROJECT_NAME} up -d --build --remove-orphans --no-recreate); \
	else \
		(export DB_NAME=${DB_NAME_DEV} && docker-compose -p ${COMPOSE_PROJECT_NAME} up -d --build --remove-orphans --no-recreate); \
	fi
	@docker-compose -p ${COMPOSE_PROJECT_NAME} up -d --build --remove-orphans --no-recreate
	# adds user and update permissions
	@if [[ "${OS_USER_NAME}" != "root" ]] && [[ ${OS_USER_ID} -ne 0 ]]; then \
		docker exec -i \
			$(CONTAINER_FPM) \
			useradd -M -u ${OS_USER_ID} -U -G www-data ${OS_USER_NAME};\
		docker exec -i \
			-w /app \
			$(CONTAINER_FPM) \
			chown -R ${OS_USER_ID}:www-data .;\
	fi
	# installs additional software
	@if [[ '$(expr length "${ADDITIONAL_SOFT_LIST}")' != "0" ]]; then \
		docker exec -i \
			$(CONTAINER_FPM) \
			bash -c \
				"add-apt-repository -y universe && apt update && apt install -ym --no-install-recommends --no-install-suggests ${ADDITIONAL_SOFT_LIST}"; \
	fi
	# starts cron jobs
	-@docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./yii dashboard/task/reload
	# recreates search index
	@sleep 10 # pause for search db init
	-@docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./yii dashboard/search/erase
	# checks
	@$(PING_APP)


.PHONY: stop
stop: $(PROJECT_DIR)/.env ## Stops project.
	# removes containers
	-@docker-compose down --remove-orphans
	# removes certificates
	-@rm $(CONF_CERTS_DIR)/cert.*


.PHONY: restart
restart: ## Restarts project.
	-@$(MAKE) stop
	@$(MAKE) start


.PHONY: ssh
ssh: ## Connects to the container with application.
	@docker exec -it \
		-w /app \
		$(CONTAINER_FPM) \
		bash


.PHONY: update
update: ## Updates OS
	@docker exec -i \
		$(CONTAINER_FPM) \
		bash -c \
			"apt update && apt dist-upgrade -y && apt full-upgrade -y"
	# cleans garbage
	-@docker exec -i \
		$(CONTAINER_FPM) \
		bash -c \
			"apt autoclean -y && apt autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"


##@ Application

.PHONY: install
install: start $(APP_DIR)/vendor ## Installs application.
	# creates additional directories
	@docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		bash -c "mkdir -p ./userdata/files/uploads ./userdata/images/uploads"
	# initiates framework
	@$(INIT_YII)
	# ping
	@$(PING_APP)
	# creates RBAC config
	@docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./yii dashboard/user/rbac
	# creates user
	@docker exec -i \
		-w /app \
		$(CONTAINER_FPM) \
		php ./yii dashboard/user/create "${ADMIN_USER_NAME}" "${ADMIN_USER_EMAIL}" "${ADMIN_USER_PASSWORD}" root --force=yes
	# updates permissions
	@$(SET_PERMISSIONS)
	# restarts
	@$(MAKE) restart
	# updates os
	@$(MAKE) update


$(APP_DIR)/vendor: $(APP_DIR)/composer.json
	@$(COMPOSER_DEPS)

.PHONY: composer
composer: ## Installs/upgrades dependencies.
	@$(COMPOSER_DEPS)
	@$(SET_PERMISSIONS)


.PHONY: mode
mode: $(PROJECT_DIR)/.env ## Changes mode (dev|prod) defined in .env.
	# defines database
	-@if [[ "${APP_MODE}" == "prod" ]]; then \
		docker exec -i \
			$(CONTAINER_DB) \
			createdb -U ${DB_USER} -O ${DB_USER} -e ${DB_NAME_PROD}; \
	else \
		docker exec -i \
			$(CONTAINER_DB) \
			createdb -U ${DB_USER} -O ${DB_USER} -e ${DB_NAME_DEV}; \
	fi
	# upgrades dependencies
	@rm -rf $(APP_DIR)/vendor
	@$(COMPOSER_DEPS)
	# initiates framework
	@$(INIT_YII)
	# updates permissions
	@$(SET_PERMISSIONS)
	# restarts
	@$(MAKE) restart


##@ Tools

.PHONY: perm
perm: ## Sets permissions for project.
	@$(SET_PERMISSIONS)


.PHONY: ping
ping: ## Sends checking http request.
	@$(PING_APP)


##@ Database

.PHONY: backup
backup: $(PROJECT_DIR)/.env ## Backs up the databases.
	@docker run --rm --volumes-from $(CONTAINER_DB) \
		 -v $(DB_BACKUP_DIR):/backup busybox:latest \
		 tar -cz -f "/backup/$$(date +'%Y%m%d').tgz" ${POSTGRES_DATA}


BACKUP_FILE=none
.PHONY: restore
restore: $(PROJECT_DIR)/.env stop ## Restores the databases.
	@if [[ "$(BACKUP_FILE)" == "none" ]]; then \
		echo "Add backup filename from /db/backup without full path, e.g.: make restore BACKUP_FILE=20190612.tgz"; \
	else \
		if [[ ! -f $(DB_BACKUP_DIR)/$(BACKUP_FILE) ]]; then \
			echo "The $(BACKUP_FILE) file is not found."; \
		else \
			docker run --rm -v $(CONTAINER_DB)-data:${POSTGRES_DATA}:rw \
				-v $(DB_BACKUP_DIR):/backup busybox:latest \
				/bin/sh -c "rm -rf ${POSTGRES_DATA}/* && tar -xz -C / -f /backup/$(BACKUP_FILE)"; \
		fi; \
	fi
	# restarts
	@$(MAKE) start
