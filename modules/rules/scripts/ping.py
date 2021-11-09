import subprocess
import json
from subprocess import TimeoutExpired, CalledProcessError, SubprocessError


def handler(event, context):
    event_dict = json.loads(event)
    parameters = event_dict['queryParameters']
    domain = parameters['domain']

    response_body = 'domain name must be provided as query string'
    status = '400'
    if domain:
        try:
            rc = subprocess.run(['ping', '-c1', '-q', domain], timeout=30).returncode
            response_body = 'success' if rc == 0 else 'failed'
            status = '200'
        except (TimeoutExpired, CalledProcessError):
            response_body = 'failed'
            status = '200'
        except OSError as err:
            response_body = err.strerror
            status = '500'
        except SubprocessError:
            response_body = 'Internal Server Error'
            status = '500'

    rep = {
        'isBase64Encoded': 'false',
        'statusCode': status,
        'headers': {
            'Content-type': 'text/plain',
            'x-custom-header': 'no'
        },
        'body': response_body
    }
    return json.dumps(rep)

