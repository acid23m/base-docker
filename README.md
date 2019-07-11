# Dockerized Yii based application

**All operations must be done in project's root directory.
Web application always use HTTPS protocol.**

## Configuration

First of all define global environment variables in .env file.
Create .env file from template .env.example.

```bash
cp -a ./.env.example ./.env
nano ./.env
```

Script, which updates project permissions, can be configured.

```bash
nano ./conf/appperm/appperm.yml
```

## Help commands

Use `make` tool to execute actions. Run `make` without parameters
to display the list of all available commands.

```bash
make
```

## Install

Use `install` action for `make` to deploy the project.

```bash
make install
```

## Structure

- **/app**: site directory.
- **/bin**: executable files.
- **/conf**: software settings.
- **/db**: database's backups.

It is recommend to store attributes of files/folders
while moving application to another destination (without VCS).

```bash
tar -czv --preserve-permissions --same-owner -f my-site.tar.gz my-site.com/
```

or

```bash
rsync -av wuser@123.456.789.000:/var/www/my-site.com /home/user/backup/
```
