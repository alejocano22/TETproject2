#!/bin/bash -ex

if ! [ `whoami` = root ]; then
  sudo bash $0
  exit 0
fi

#
# setup environment
#

cd /home/ec2-user/

# update and install
yum update -y
yum upgrade -y
yum install git docker -y
yum install -y emacs

# install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# enable docker
systemctl start docker.service
systemctl enable docker.service

#
# setup docker image
#

cat << "EOF" > docker-compose.yml
version: '2'
services:
  moodle:
    container_name: moodle
    restart: always
    image: 'bitnami/moodle:3'
    environment:
      - MARIADB_HOST=dbmoodle2.crbs80gvnvpm.us-east-1.rds.amazonaws.com
      - MARIADB_PORT_NUMBER=3306
      - MOODLE_DATABASE_USER=bn_moodle
      - MOODLE_DATABASE_NAME=dbmoodle2
      - MOODLE_DATABASE_PASSWORD=cano1999
      - MOODLE_SKIP_INSTALL=yes
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - './moodle_data:/bitnami'

    depends_on:
      - s3vol
  s3vol:
    container_name: s3
    restart: always
    image: elementar/s3-volume
    command: /data s3://s3moodle
    volumes:
      - './moodle_data:/data'
    env_file:
      - 'credentialsaws/s3-variables.env'
EOF

# daemon to update credentials
cat << "EOF" > /usr/local/bin/update-awscredentials
#!/bin/bash
# Poner en /usr/local/bin/ y el .service en /etc/systemd/system/
# Los permisos son 744, 644
while :; do
    cd /home/ec2-user
    git clone https://ljpalaciom:u-gz6mo99W9sBjs686Db@gitlab.com/ljpalaciom/credentialsaws.git/
    success=$?
    if [ "$success" -eq 0 ]; then
        echo "Repository successfully cloned."
        chown ec2-user -R /home/ec2-user/moodle_data
    fi

    cd /home/ec2-user/credentialsaws

    git fetch
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then  # if there is something to pull
        if ! chown ec2-user -R /home/ec2-user/moodle_data; then
            logger "Error al cambiar usuario de la carpeta moodle_data"
        else
            logger "Actualizados los permisos de la carpeta moodle_data"
        fi
    fi

    if ! git pull origin master; then
        logger "Error al actualizar web"
    fi

    if ! docker-compose up -d --build; then
        logger "Error al restablecer el contenedor"
    fi
    sleep 20s
done

EOF

cat << "EOF" > /etc/systemd/system/update-awscredentials.service
[Unit]
Description=Update aws credentials
After=networking.target

[Service]
ExecStart=/usr/local/bin/update-awscredentials

[Install]
WantedBy=multi-user.target

EOF

chmod 744 /usr/local/bin/update-awscredentials
chmod 644 /etc/systemd/system/update-awscredentials.service
systemctl daemon-reload
systemctl enable update-awscredentials
systemctl start update-awscredentials