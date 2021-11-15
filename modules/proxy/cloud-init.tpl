PORT=${port}
ENCRYPTION_ALGORITHM=${encryption_algorithm}
PASSWORD=${password}
AWSLOGS_REGION=${awslogs_region}
AWSLOGS_GROUP=${awslogs_group}
AWSLOGS_STREAM=${awslogs_stream}
AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

yum update -y
amazon-linux-extras install docker
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> /etc/sysconfig/docker
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /etc/sysconfig/docker
service docker start
mkdir /etc/shadowsocks-rust && cat > /etc/shadowsocks-rust/config.json <<EOF
{
    "server": "::",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "method": "$ENCRYPTION_ALGORITHM"
}
EOF
if [ -n "$AWSLOGS_REGION" ]
then
  LOG_OPTIONS="--log-driver=awslogs --log-opt awslogs-region=$AWSLOGS_REGION --log-opt awslogs-group=$AWSLOGS_GROUP --log-opt awslogs-stream=$AWSLOGS_STREAM"
fi
docker run --name ssserver-rust \
  --restart always \
  -p $PORT:$PORT \
  -v /etc/shadowsocks-rust/config.json:/etc/shadowsocks-rust/config.json \
  $LOG_OPTIONS \
  -dit ghcr.io/shadowsocks/ssserver-rust:v1.11.2 -v
