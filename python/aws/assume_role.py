#list users in another account while assuming a role in that other account
import boto3
from boto3.session import Session

print('Enter account id:')
account = input()
print('Querying, ' + account) 

sts_client = boto3.client('sts')

try:
    response = sts_client.assume_role(
        RoleArn='arn:aws:iam::'+account+':role/SomeIAMRole',
        RoleSessionName='assume_role_session'
    )
except ClientError as error:
    print('Unexpected error occurred... could not assume role', error)

try:
    iam_client = boto3.client('iam',
                              aws_access_key_id=response['Credentials']['AccessKeyId'],
                              aws_secret_access_key=response['Credentials']['SecretAccessKey'],
                              aws_session_token=response['Credentials']['SessionToken']
                              )
except ClientError as error:
    print('Unexpected error occurred... could not create iam client on trusting account', error)

try:
    users_paginator = iam_client.get_paginator('list_users')
    for usersresp in users_paginator.paginate():
        for user in usersresp['Users']:
            print("getting access keys for " + user['UserName'])
            accesskeys_paginator = iam_client.get_paginator('list_access_keys')
            for accesskeys_response in accesskeys_paginator.paginate(UserName=user['UserName']):
                for accesskey in accesskeys_response['AccessKeyMetadata']:
                    print("--- " + accesskey['AccessKeyId'] + " " + accesskey['Status'] + " " + str(accesskey['CreateDate']) )
            
except ClientError as error:
    if error.response['Error']['Code'] == 'NoSuchEntityException':
        print('There is no user with name {0}'.format(user_name))
    else:
        print('Unexpected error occurred... exiting from here', error)
