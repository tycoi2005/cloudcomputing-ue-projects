#!/bin/bash -xe

# Set environment variables for the application and AWS SDK
# These will be passed in by the Launch Template
export DB_SECRET_ARN="${db_secret_arn}"
export AWS_REGION="${aws_region}"
export APP_PORT=80

LOG_FILE="/home/ubuntu/log.txt"

# Install dependencies
apt-get update -y
apt-get install -y nodejs unzip wget npm mysql-client

# Download and prepare application code
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-91571/1-lab-capstone-project-1/code.zip -P /home/ubuntu
cd /home/ubuntu
unzip code.zip -x "resources/codebase_partner/node_modules/*"
cd resources/codebase_partner
npm install aws aws-sdk >> $LOG_FILE 2>&1

# This section modifies the application's source code to use the secret ARN
CONFIG_FILE="app/config/config.js"
if [ -f "$CONFIG_FILE" ]; then
    sed -i "s|const secretName = \"Mydbsecret\";|const secretName = process.env.DB_SECRET_ARN;|" $CONFIG_FILE
fi

# Start the application in the background and log output
npm start >> $LOG_FILE 2>&1 &

echo '#!/bin/bash -xe
    cd /home/ubuntu/resources/codebase_partner
    export DB_SECRET_ARN="${db_secret_arn}"
    export AWS_REGION="${aws_region}"
    export APP_PORT=80
    npm start >> $LOG_FILE 2>&1 &' > /etc/rc.local
chmod +x /etc/rc.local