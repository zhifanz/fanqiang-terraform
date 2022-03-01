aws configure set aws_access_key_id ${access_key.id}
aws configure set aws_secret_access_key ${access_key.secret}
yum update -y
amazon-linux-extras install docker
service docker start
curl --silent -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

SHADOWSOCKS_HOME=/opt/shadowsocks
mkdir $SHADOWSOCKS_HOME && aws s3 cp ${artifacts.common_uri} $SHADOWSOCKS_HOME/ --recursive
%{ if artifacts.extends_uri != null }aws s3 cp ${artifacts.extends_uri} $SHADOWSOCKS_HOME/ --recursive%{ endif }
alias dc="docker-compose --project-directory $SHADOWSOCKS_HOME"
dc up --no-start
%{ if artifacts.extends_uri != null }dc start fluentbit%{ endif }
dc start shadowsocks
