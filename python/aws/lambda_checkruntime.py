# inspired by https://gist.github.com/reecestart/0f613f1fc10f475d909e8107a6e8dcb2#file-lambdadeprecationschedule-py
# pull all regions, pull all lambda's, check runtime

import boto3
from botocore.exceptions import ClientError

# get all regions
ec2client = boto3.client('ec2')
response = ec2client.describe_regions(
    AllRegions=True
)
regionNames = []
for i in response['Regions']:
    regionNames.append(i['RegionName'])

# get all lambdas
Lambdas = []
for regionName in regionNames:
    lambdaclient = boto3.client('lambda', region_name=regionName)
    try:
        print("querying region " + regionName )
        response = lambdaclient.list_functions()
        if len(response['Functions']) > 0:
            Lambdas.append({'Region': regionName, 'Functions': response['Functions']})
    except Exception: 
        pass
        
# print
for entry in Lambdas:
    print("  ========= found in " + entry['Region'] + " =========")
    for function in entry['Functions']:
        print ('| {:<125} | {:^15} |'.format(function['FunctionArn'], function['Runtime']))
