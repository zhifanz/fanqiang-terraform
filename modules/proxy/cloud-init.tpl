yum update -y
amazon-linux-extras install docker
%{ if awslogs != null }
echo "AWS_ACCESS_KEY_ID=${awslogs.agent_access_key.id}" >> /etc/sysconfig/docker
echo "AWS_SECRET_ACCESS_KEY=${awslogs.agent_access_key.secret}" >> /etc/sysconfig/docker
%{ endif }
service docker start

SHADOWSOCKS_CONFIG=/etc/shadowsocks-rust/config.json
yum install jq -y
mkdir /etc/shadowsocks-rust && curl -o $SHADOWSOCKS_CONFIG ${shadowsocks_config_url}
PORT=$(jq --compact-output .server_port $SHADOWSOCKS_CONFIG)
REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)

docker run --name ssserver-rust \
  --restart always \
  -p $PORT:$PORT \
  -v $SHADOWSOCKS_CONFIG:/etc/shadowsocks-rust/config.json \
  %{~ if awslogs != null ~}
  --log-driver=awslogs \
  --log-opt awslogs-region=${awslogs.region} \
  --log-opt awslogs-group=${awslogs.group} \
  --log-opt awslogs-stream=$REGION  \
  %{~ endif ~}
  -dit ghcr.io/shadowsocks/ssserver-rust:v1.11.2 -v
