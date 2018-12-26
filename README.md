# Dockerized Yii based application

All operations must be done in project directory root.
Web application always use HTTPS protocol.

## Configuration

First of all define global environment variables in .env file.
Create .env file from template .env.example.

```bash
cp -a ./.env.example ./.env
chmod 640 ./.env*
nano ./.env
```

Change database host from "localhost" to "db" in
environment configuration files.

```bash
nano ./app/environments/dev/common/main-local.php
nano ./app/environments/prod/common/main-local.php
```

Script, which updates project permissions, can be configured.

```bash
nano ./conf/appperm/appperm.yml
```

Protect your project by setting access rights.

```bash
chown -R $(id -un):$(id -gn) .
find . -type d -exec chmod 750 {} \;
find . -type f -exec chmod 640 {} \;
find ./conf/ -type d -exec chmod 755 {} \;
find ./conf/ -type f -exec chmod 644 {} \;
chmod u+x ./*.sh
chmod u+x ./bin/*
bin/appperm -c conf/appperm/appperm.yml -u $(id -un) app/
```

## Containers

Use script *start.sh* to create and launch docker containers.

```bash
./start.sh
```

## Install

Use script *install.sh* to install application.

```bash
./install.sh
```

## Structure

- **/app**: site directory. The owner of this folder must be *{$USER}:www-data*.
- **/bin**: executable files.
- **/conf**: software settings.
- **/db**: database\'s backups.

It is recommend store attributes of files/folders
while moving application to another destination (without VCS).

```bash
tar -czv --preserve-permissions --same-owner -f my-site.tar.gz my-site.com/
```

or

```bash
rsync -av wuser@123.456.789.000:/var/www/my-site.com /home/user/backup/
```

## Scripts

- **start.sh**: launch application - start containers and create volume.
- **stop.sh**: stop application - stop and remove containers.
- **install.sh**: deploy application. Edit script depending app version.
- **change-mode.sh**: change application mode (*prod|dev*) defined in .env.
- **command.sh**: start command line inside app container at */app* work directory.
- **composer-update.sh**: update application packages.
- **backup-db.sh**: create gziped tar archive *backup-\[Ymd\]).tgz* at *./db/backup* directory from volume.
Usage: ./backup-db.sh [dump name]
- **restore-db.sh**: unpack archive at *./db/backup* directory to volume.
STOP CONTAINERS BEFORE RESTORE!
