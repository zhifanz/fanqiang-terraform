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

%{ if ra != null }
yum -y install docker
systemctl start docker
docker pull public.ecr.aws/zhifanz/fanqiang-update-ping
CONTINENT=$(echo $REGION | cut -d- -f1)
crontab <<EOF
0 * * * * docker run -e AWS_ACCESS_KEY_ID="${ra.access_key.id}" -e AWS_SECRET_ACCESS_KEY="${ra.access_key.secret}" --rm ${ra.image_uri} --days ${ra.days_to_scan} --pingcount ${ra.ping_count} ${ra.dynamodb_table} $CONTINENT
EOF
%{ endif }