# Dockerized Yii based application

All operations must be done in project directory.
Web application always use HTTPS protocol.

## Configuration

First of all define global environment variables
in .env file.
Create .env file from template .env.example.

```bash
cp -a ./.env.example ./.env
nano ./.env
```

Change database host from "localhost" to "db" in
environment configuration files.

```bash
nano ./app/environments/dev/common/main-local.php
nano ./app/environments/prod/common/main-local.php
```

## Containers

Use script *run.sh* to create and launch docker containers.

```bash
./run.sh
```

## Install

Use script *install.sh* to install application.

```bash
./install.sh
```

## Structure

- **/app**: site directory. The owner of this folder must be *{$USER}:www-data*.
- **/bin**: executable scripts.
- **/conf**: software settings.
- **/db**: database\'s data and backups.
- **/logs**: server logs.

It is recommend store attributes of files/folders
while moving application to another destination.

```bash
tar -czv --preserve-permissions --same-owner -f my-site.tar.gz my-site.com/
```

or

```bash
rsync -av wuser@123.456.789.000:/var/www/my-site.com /home/user/backup/
```
