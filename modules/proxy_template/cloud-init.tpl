aws configure set aws_access_key_id ${access_key.id}
aws configure set aws_secret_access_key ${access_key.secret}
yum update -y
amazon-linux-extras install docker
service docker start

SHADOWSOCKS_HOME=/opt/shadowsocks
mkdir $SHADOWSOCKS_HOME && aws s3 cp ${artifacts.root_uri} $SHADOWSOCKS_HOME/ --recursive
curl --silent -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --file $SHADOWSOCKS_HOME/${artifacts.compose_file} %{ if artifacts.compose_override_file != null } --file $SHADOWSOCKS_HOME/${artifacts.compose_override_file} %{ endif } up --detach
