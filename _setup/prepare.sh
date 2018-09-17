#!/bin/bash
set -e
# Simple Bash Script to configure the UserSetup_Cloudformation.template and Connect User File

# Yaml file name
FILE_NAME="IAMSetup_Cloudformation"
CONNECT_FILE_NAME="AMAZON_CONNECT_USERS.csv"

# Ask the user how many users that would like configured
read -p 'How many users to be configured?: ' USERCOUNT

# Check if the inputted value is a number
re='^[0-9]+$'
if ! [[ $USERCOUNT =~ $re ]] ; then
   echo "[ERROR]: Please input a number" >&2; exit 1
fi

DIR=$(cd `dirname $0` && pwd)
cd $DIR

# Make a copy of the template yaml
cp $FILE_NAME.template.yaml $FILE_NAME.yaml

# Create the Connect user csv header
CONNECT_HEADERS="first name,last name,email address,password,\
                user login,routing profile name,security_profile_name_1|security_profile_name_2,\
                phone type (soft/desk),phone number,soft phone auto accept (yes/no),\
                ACW timeout (seconds)"

# Write headers to file
echo $CONNECT_HEADERS > $CONNECT_FILE_NAME

for (( i = 1; i <= USERCOUNT; ++i )); do

    # Define the AWS Console and Connect password
    PASS=$(openssl rand -base64 10)

    # Define the user yaml
    USER_YAML=$(cat <<-END
    User$i:
        Type: "AWS::IAM::User"
        Properties:
            Groups:
             - !Ref PlaygroundGroup
            LoginProfile:
                Password: $PASS
                PasswordResetRequired: false
            Path: /
            UserName: user$i

END
)   
    echo "user$i / $PASS"
    echo "$USER_YAML" >> $FILE_NAME.yaml

    # Add user entry to the Connect file
    echo "user$i,user$i,user$i@user$i.com,$PASS,user$i,\
          Basic Routing Profile,CallCenterManager|Agent,soft,,no,0" >> $CONNECT_FILE_NAME
done 

echo "$FILE_NAME.yaml ready to load into AWS."

echo "$CONNECT_FILE_NAME.yaml ready to load into Amazon Connect."