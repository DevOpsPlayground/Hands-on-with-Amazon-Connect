import json
import datetime
import time
import os
import dateutil.parser
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def close(session_attributes, fulfillment_state, message):
    response = {
        'sessionAttributes': session_attributes,
        'dialogAction': {
            'type': 'Close',
            'fulfillmentState':  fulfillment_state,
            'message': message
        }
    }

    return response


def leave_message(intent_request):
    session_attributes = intent_request['sessionAttributes']
    slots = intent_request['currentIntent']['slots']
    myName = slots['MyName']
    CallReason = slots['CallReason']
    myDate = slots['Date']
    myTime = slots['Time']
    CompanyName = slots['CompanyName']
    message = myName + ' from ' + CompanyName + ' called regarding ' + CallReason + '. Please call back by' + ' Date:' + myDate + '  Time:' + myTime
    logger.debug(message)
    client = boto3.client('sns')
    response = client.publish(
        TargetArn=os.environ['TopicArn'],
        Message=message,
        Subject='Mailbox Message'
    )
    return close(
        session_attributes,
        'Fulfilled' ,
        {
            'contentType':'PlainText',
            'content': 'Thank you, your message has been sent'
        }
    )


def dispatch(intent_request):
    logger.debug('dispatch userId={}, intentName={}'.format(intent_request['userId'], intent_request['currentIntent']['name']))
    intent_name = intent_request['currentIntent']['name']

    if intent_name == 'LeaveMessage':
        return leave_message(intent_request)

    raise Exception('Intent with name ' + intent_name + ' not supported')



def lambda_handler(event, context):
    logger.debug(json.dumps(event))
    logger.debug('event.bot.name={}'.format(event['bot']['name']))


    return dispatch(event)
