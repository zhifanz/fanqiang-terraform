import logging
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import urllib
from urllib import request

def to_yaml_payload(domains):
    if domains:
        return 'payload:' + ''.join([f'\n  - {d}' for d in domains])
    else:
        return 'payload: []'

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    response = table.query(ProjectionExpression='domainName')
    white_list = []

    for item in response['Items']:
        domain_name = item['domainName']
        require_proxy = True
        try:
            with urllib.request.urlopen(os.environ['PING_SERVICE_ENDPOINT'] + '?domain=' + domain_name) as r:
                if r.status == 200 and r.read().decode() == 'success':
                    require_proxy = False
                    white_list.append(domain_name)
            table.update_item(
                Key = {
                    'domainName': domain_name
                },
                UpdateExpression = 'SET requireProxy = :v',
                ExpressionAttributeValues = {
                    ':v': require_proxy
                }
            )
        except:
            logging.error('Error checking domain: ' + domain_name)

    s3 = boto3.resource('s3')
    bucket = s3.Bucket(os.environ['BUCKET'])
    bucket.put_object(
        ACL = 'public-read',
        Body = to_yaml_payload(white_list).encode(),
        ContentType = 'text/plain',
        Key = os.environ['OBJECT_PATH']
    )
        
        
