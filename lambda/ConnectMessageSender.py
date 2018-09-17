import boto3
import os
import json


def lambda_handler(event, context):
    message = json.dumps(event);
    'Send to SNS the captured message'
    client = boto3.client('sns')
    response = client.publish(
        TargetArn = os.environ['TopicArn'],
        Message=message,
        Subject='Mailbox Message'
        )
        
    return {'MessageSender' : 'Message Sent'}
