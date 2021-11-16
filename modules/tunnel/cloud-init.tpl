#!/bin/bash

ELASTIC_IP_ALLOCATION_ID=${elastic_ip_allocation_id}
NGINX_CONF_URL=${nginx_conf_url}

REGION="$(curl --silent http://100.100.100.200/latest/meta-data/region-id)"
aliyun configure set --region $REGION --mode EcsRamRole \
  --ram-role-name "$(curl --silent http://100.100.100.200/latest/meta-data/ram/security-credentials/)"
aliyun --endpoint "vpc-vpc.$REGION.aliyuncs.com" vpc AssociateEipAddress \
  --AllocationId $ELASTIC_IP_ALLOCATION_ID \
  --InstanceId "$(curl --silent http://100.100.100.200/latest/meta-data/instance-id)"

until ping -c1 aliyun.com &>/dev/null ; do sleep 1 ; done
yum install -y nginx nginx-all-modules
curl -o /etc/nginx/nginx.conf $NGINX_CONF_URL
systemctl start nginx
