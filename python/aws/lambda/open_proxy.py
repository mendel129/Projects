#use aws lambda to proxy a request
#in this case to add cors headers to a website which doesnt has cors headers
#todo: add authentication, an open proxy is never a good idea!
#todo2: not sure if url needs to be from urlpath, maybe hardcode

import json,urllib3,base64

def lambda_handler(event, context):
    vara=event['queryStringParameters']['vara']
    varb=event['queryStringParameters']['varb']
    url=event['queryStringParameters']['url']
    varc=event['queryStringParameters']['varc']
    
    payload=base64.b64encode((vara+":"+varb).encode('ascii')).decode('ascii')
    encoded_body="grant_type=password&username=idontexist&password="+varc

    http = urllib3.PoolManager()
    req_headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': "Basic " + payload,
    }
    
    r = http.request('POST', url, headers=req_headers, body=encoded_body)
    resp= r.data.decode('utf-8')

    return {
        'statusCode': 200,
        'body': json.dumps(str(resp))
    }
