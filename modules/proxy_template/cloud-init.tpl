aws configure set aws_access_key_id ${access_key.id}
aws configure set aws_secret_access_key ${access_key.secret}
yum update -y
amazon-linux-extras install docker
%{ if log_group != null }
DOCKER_CONFIG_DIR=/etc/systemd/system/docker.service.d
[ -d $DOCKER_CONFIG_DIR ] || mkdir -p $DOCKER_CONFIG_DIR
tee $DOCKER_CONFIG_DIR/aws.conf <<EOF
[Service]
Environment="AWS_ACCESS_KEY_ID=${access_key.id}"
Environment="AWS_SECRET_ACCESS_KEY=${access_key.secret}"
EOF
%{ endif }
service docker start

SHADOWSOCKS_CONFIG=/etc/shadowsocks-rust/config.json
yum install jq -y
mkdir $(dirname $SHADOWSOCKS_CONFIG) && aws s3 cp ${shadowsocks_config_uri} $SHADOWSOCKS_CONFIG
PORT=$(jq --compact-output .server_port $SHADOWSOCKS_CONFIG)
REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)

docker run --name ssserver-rust \
  --restart always \
  -p $PORT:$PORT \
  -v $SHADOWSOCKS_CONFIG:$SHADOWSOCKS_CONFIG \
  %{~ if log_group != null ~}
  --log-driver=awslogs \
  --log-opt awslogs-region=$REGION \
  --log-opt awslogs-group=${log_group} \
  --log-opt awslogs-stream=$INSTANCE_ID \
  %{~ endif ~}
  -dit ghcr.io/shadowsocks/ssserver-rust:v1.11.2 %{ if log_group != null } -v %{ endif }

%{ if ra != null }
crontab <<EOF
0 * * * * docker run -e AWS_ACCESS_KEY_ID="${access_key.id}" -e AWS_SECRET_ACCESS_KEY="${access_key.secret}" --rm ${ra.image_uri} --days ${ra.days_to_scan} --pingcount ${ra.ping_count} ${ra.dynamodb_table} ${ra.continent}
EOF
%{ endif }