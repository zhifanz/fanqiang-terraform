#!/bin/bash

PROXY_PORT=${proxy_port}
PROXY_ADDRESS=${proxy_address}
ELASTIC_IP_ALLOCATION_ID=${elastic_ip_allocation_id}


REGION="$(curl --silent http://100.100.100.200/latest/meta-data/region-id)"
aliyun configure set --region $REGION --mode EcsRamRole \
  --ram-role-name "$(curl --silent http://100.100.100.200/latest/meta-data/ram/security-credentials/)"
aliyun --endpoint "vpc-vpc.$REGION.aliyuncs.com" vpc AssociateEipAddress \
  --AllocationId $ELASTIC_IP_ALLOCATION_ID \
  --InstanceId "$(curl --silent http://100.100.100.200/latest/meta-data/instance-id)"

until ping -c1 aliyun.com &>/dev/null ; do sleep 1 ; done

yum install -y nginx nginx-all-modules python3

cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
  worker_connections 1024;
}

stream {
  server {
    listen $PROXY_PORT;
    proxy_pass $PROXY_ADDRESS:$PROXY_PORT;
  }
}
EOF

systemctl start nginx
