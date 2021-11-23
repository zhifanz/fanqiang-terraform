aws configure set aws_access_key_id ${agent_user.access_key.id}
aws configure set aws_secret_access_key ${agent_user.access_key.secret}
yum update -y
amazon-linux-extras install docker
DOCKER_CONFIG_DIR=/etc/systemd/system/docker.service.d
[ -d $DOCKER_CONFIG_DIR ] || mkdir -p $DOCKER_CONFIG_DIR
tee $DOCKER_CONFIG_DIR/aws.conf <<EOF
[Service]
Environment="AWS_ACCESS_KEY_ID=${agent_user.access_key.id}"
Environment="AWS_SECRET_ACCESS_KEY=${agent_user.access_key.secret}"
EOF
service docker start

SHADOWSOCKS_CONFIG=/etc/shadowsocks-rust/config.json
yum install jq -y
mkdir $(dirname $SHADOWSOCKS_CONFIG) && aws s3 cp ${shadowsocks_config_url} $SHADOWSOCKS_CONFIG
PORT=$(jq --compact-output .server_port $SHADOWSOCKS_CONFIG)
REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)

docker run --name ssserver-rust \
  --restart always \
  -p $PORT:$PORT \
  -v $SHADOWSOCKS_CONFIG:/etc/shadowsocks-rust/config.json \
  --log-driver=awslogs \
  --log-opt awslogs-region=${log_group.region} \
  --log-opt awslogs-group=${log_group.name} \
  --log-opt awslogs-stream=$REGION  \
  -dit ghcr.io/shadowsocks/ssserver-rust:v1.11.2 -v
