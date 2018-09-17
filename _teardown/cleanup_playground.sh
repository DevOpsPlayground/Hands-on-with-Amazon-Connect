#!/bin/bash
set -e
# Simple Bash Script to cleanup the playground environment

#  ***********************************   WARNING   ********************************************
# EXECUTING THIS SCRIPT WILL REMOVE ALL S3 BUCKETS, LAMBDA FUNCTIONS, SNS TOPICS, 
# CLOUDFORMATION STACK UNDER THE N. VIRGINIA REGION, AND ALL LEX BOTS ACROSS ALL REGIONS.
# DO NOT RUN THIS SCRIPT IF YOU USE YOUR AWS ACCOUNT PURPOSES OTHER THAN THIS PLAYGROUND
#  ***********************************   WARNING   ********************************************


read -p " ***** WARNING ****** EXECUTING THIS SCRIPT WILL REMOVE ALL S3 BUCKETS, LAMBDA FUNCTIONS, SNS TOPICS, \
CLOUDFORMATION STACK UNDER THE N. VIRGINIA REGION, AND ALL LEX BOTS ACROSS ALL REGIONS. \
DO NOT RUN THIS SCRIPT IF YOU USE YOUR AWS ACCOUNT PURPOSES OTHER THAN THIS PLAYGROUND. Are you sure you want to continue? " answer
case ${answer:0:1} in
    y|Y )
        echo "You selected YES. Continuing"
    ;;
    * )
        echo "Aborting run. Bye!"
    ;;
esac

export AWS_DEFAULT_REGION=us-east-1

### DELETE LEX BOTS ###
# No restriction where the bot can be created, therefore check all three regions #
for h in us-east-1 us-west-2 eu-west-1; do

export AWS_DEFAULT_REGION=$h

        # Get list of bots
        BOT_LIST=$(aws lex-models get-bots --output json)

        # Loop through each bot
        for i in $(echo $BOT_LIST | jq --raw-output .bots[].name); do
        echo "[ INFO ]: Getting Aliases for $i"
        BOT_ALIASES=$(aws lex-models get-bot-aliases --output json --bot-name $i)

        # Loop though each bot alias and delete
        for j in $(echo $BOT_ALIASES | jq --raw-output .BotAliases[].name); do
            echo "[ INFO ]: Deleting alias $j for bot $i"
            aws lex-models delete-bot-alias --name $j --bot-name $i
        done

        echo "[ INFO ]: Deleting Bot $i"
        aws lex-models delete-bot --name $i
        echo "[ INFO ]: Bot $i deleted"
        done
done

export AWS_DEFAULT_REGION=us-east-1

### DELETE CLOUDFORMATION STACKS ###

echo "[ INFO ]: Getting list of Cloudformation Stacks"

# Get list of cloudformation stacks
STACK_LIST=$(aws cloudformation list-stacks --output json)

# Loop through each stack
for i in $(echo $STACK_LIST | jq --raw-output '.StackSummaries[] | select(.StackStatus=="CREATE_COMPLETE").StackName'); do

 echo "[ INFO ]: Deleting Stack $i"
 aws cloudformation delete-stack --stack-name $i
 echo "[ INFO ]: Stack $i deleted"

done


### DELETE SNS SUBSCRIPTIONS ###

echo "[ INFO ]: Getting list of SNS subscriptions"

# Get list of subscriptions
SNS_SUBSCRIPTIONS=$(aws sns list-subscriptions --output json)

# Loop through each subscription
for i in $(echo $SNS_SUBSCRIPTIONS | jq --raw-output '.Subscriptions[] | select(.SubscriptionArn!="PendingConfirmation").SubscriptionArn'); do

 echo "[ INFO ]: Deleting subscription $i"
 aws sns unsubscribe --subscription-arn $i
 echo "[ INFO ]: Subscription $i deleted"

done


### DELETE S3 BUCKETS ###

# Get list of S3 buckets
echo "[ INFO ]: Getting list of S3 buckets"
BUCKET_LIST=$(aws s3api list-buckets --output json)

# Loop through each bucket
for i in $(echo $BUCKET_LIST | jq --raw-output .Buckets[].Name); do

    # Get list of objects
    echo "[ INFO ]: Getting object list for bucket $i"
    OBJECT_LIST=$(aws s3api list-objects-v2 --bucket $i --output json)

    # Loop though each object and delete
    for j in $(echo $OBJECT_LIST | jq --raw-output .Contents[].Key); do
        echo "[ INFO ]: Deleting object $j from bucket $i"
        aws s3api delete-object --bucket $i --key $j
    done

    echo "[ INFO ]: Deleting bucket $i"
    aws s3api delete-bucket --bucket $i
    echo "[ INFO ]: Bucket $i deleted"
done