# this is probably not recommended :-)
# feel free to try stuff out
# get jwt
# get expiration, issuer, compare with known info
# get jwks and search for kid from jwt
# validate signature

import base64, hashlib, hmac, json, urllib3, time

def base64url_to_int(b64url):
    return int(base64.urlsafe_b64decode(b64url + '==').hex(), 16)

def get_public_key_from_jwks(jwks_url, kid):
    http = urllib3.PoolManager()
    response = http.request('GET', jwks_url)
    resp_data=response.data.decode('utf-8')
    jwks_data = json.loads(resp_data)

    for key in jwks_data['keys']:
        if key['kid'] == kid and key['kty'] == 'RSA':
            return {
                'n': key['n'],
                'e': key['e']
            }

def validate_jwt_with_jwks(jwt_token, jwks_url):
    try:
        header, payload, signature = jwt_token.split('.')
        decoded_payload = base64.urlsafe_b64decode(payload + '==')
        payload_json=json.loads(decoded_payload)
        jwks_url_from_token = payload_json['iss']
        if(jwks_url == jwks_url_from_token+"/.well-known/jwks.json"):
            jwt_exp = payload_json['exp']
            if( int(jwt_exp) > (int(time.time())) ):
                decoded_header = base64.urlsafe_b64decode(header + '==')
                kid = json.loads(decoded_header)['kid']
                public_key = get_public_key_from_jwks(jwks_url, kid)
                if public_key is not None:
                    decoded_signature = base64.urlsafe_b64decode(signature + '==')
                    message = base64.b64encode(bytes(decoded_header.decode(), 'utf-8')).decode().rstrip("=")  + '.' + base64.b64encode(bytes(decoded_payload.decode(), 'utf-8')).decode().rstrip("=") 
                    tokensignature=hashlib.sha256(message.encode()).hexdigest()
                    e=base64url_to_int(public_key['e'])
                    n=base64url_to_int(public_key['n'])
                    jwksignature=hex(pow(base64url_to_int(signature), e, n))[-64:]
                    
                    return tokensignature == jwksignature
                else:
                    return False
            else:
                print("token expired")
                return False
        else:
            print("invalid issuer")
            return False
    except Exception as e:
        print(e)

try:
	region="eu-central-1"
	id="eu-central-1_randomid"
	jwks_url="https://cognito-idp."+region+".amazonaws.com/"+id+"/.well-known/jwks.json"
	bearer_token = event['headers']['authorization'].split(' ')[1]
	is_valid = validate_jwt_with_jwks(bearer_token, jwks_url)
  # is_valid = validate_jwt_with_jwks(bearer_token)

	if is_valid:
		print('Token is valid.')
		header, payload, signature = bearer_token.split('.')
		tokendata=json.loads(base64.urlsafe_b64decode(payload + '=='))
		print("welcome " + tokendata["username"])
		authenticated=1
	else:
		print('Token validation failed.')
except Exception as e:
  print(e)
