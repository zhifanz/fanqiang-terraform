import json
import sys
import boto3

args = json.load(sys.stdin)
url = boto3.client('s3').generate_presigned_url(
    ClientMethod='get_object',
    Params={'Bucket': args['bucket'], 'Key': args['key']},
    ExpiresIn=3600)

print(json.dumps({'url': url}), end=None)