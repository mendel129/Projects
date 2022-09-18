#use aws lambda to proxy an http request, not on purpose but for PoC get -> post
#in this case to add cors headers to a website which doesnt has cors headers
#todo: add authentication, an open proxy is never a good idea!
#todo2: not sure if url needs to be from urlpath, maybe hardcode
#todo3: convert to post -> post get data out of urlpath

import json,urllib3,base64

def lambda_handler(event, context):
    vara=event['queryStringParameters']['vara']
    varb=event['queryStringParameters']['varb']
    varc=event['queryStringParameters']['varc']
    url=event['queryStringParameters']['url']
    
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
