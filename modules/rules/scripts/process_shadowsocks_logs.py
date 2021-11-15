import base64
import json
import os
import gzip
import re
import logging
import urllib
from urllib import request
import boto3
from boto3.dynamodb.conditions import Key, Attr

DOMAIN_PATTERN = r'<-> ([\w-]+\.)*(\w+\.[a-z]+):\d+ '

def decode_events(event):
    compressed_event_data = base64.standard_b64decode(event['awslogs']['data'])
    cloudwatch_logs_message = json.loads(gzip.decompress(compressed_event_data).decode())
    return cloudwatch_logs_message['logEvents']

def is_domestic_available(domain):
    with urllib.request.urlopen(os.environ['PING_SERVICE_ENDPOINT'] + '?domain=' + domain) as r:
        return r.status == 200 and r.read().decode() == 'success'

def to_yaml_payload(domains):
    if domains:
        return 'payload:' + ''.join([f'\n  - {d}' for d in domains])
    else:
        return 'payload: []'

def update_domestic_rules(domains):
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(os.environ['BUCKET'])
    bucket.put_object(
        ACL = 'public-read',
        Body = to_yaml_payload(domains).encode(),
        ContentType = 'text/plain',
        Key = os.environ['OBJECT_PATH']
    )


def process_domain(domain):
    logging.info('process domain: ' + domain)
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    response = table.query(Select='COUNT', KeyConditionExpression=Key('domainName').eq(domain))
    if response['Count'] > 0:
        return
    is_domestic = is_domestic_available(domain)
    if is_domestic:
        response = table.scan(ProjectionExpression='domainName', FilterExpression=Attr('requireProxy').eq(False))
        domestic_domains = [item['domainName'] for item in response['Items']]
        domestic_domains.append(domain)
        update_domestic_rules(domestic_domains)
    table.put_item(Item={
        'domainName': domain,
        'requireProxy': not is_domestic
    })
    

def handler(event, context):
    for log_event in decode_events(event):
        log_message = log_event['message']
        match = re.search(DOMAIN_PATTERN, log_message)
        if match and match.lastindex:
            process_domain(match.group(match.lastindex))
