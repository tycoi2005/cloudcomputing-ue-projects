# Welcome to the Serverless Land

This lab focuses on provisioning Web services using serverless technologies in AWS. Once finalizing, you will be able to deploy a serverless website and backend.

## Context

Today you will be the CTO of your startup 🤘🤘🤘

You and the co-founder have created the coolest product and want to start your own business. The first challenge that is on the table is how to promote the business at scale, be highly available, and with minumum infrastructure and development cost. Low time to market is a must, and you and your team have 2 days to develop a PoC that will describe how the first technology will be.

After a long session refining requirements, you come out of the meeting with the following key capabilities that must be supported:

1. The product will be consumed in the US, Japanese, and European markets
2. The product needs to be accessible over internet and customers will be able to buy it online
3. Since you have a new product, there is no historical data that can give you an overview of the expected load
4. Your IT budget for infrastructure is 50 USD per year
5. For the PoC, you don't need to create (implement) a domain. However, it needs to be part of your target architecture (on paper)
6. Security is always of big concern. All data must be encrypted and no storage resources can be made public
7. You want the latency to be minimal in US, Japan and Europe, so that pictures and videos in the website will download and start with near to zero latency

## Task 1 - Frontend - S3 Website Hosting

You and your team decided that the company website frontend will be developed in React. One of your team mates already developed a template in another job. You will reuse it. The built website is zipped in `build.zip` and the complete source can be found [here](https://github.com/issaafalkattan/React-Landing-Page-Template.git) . In this task you have to:

1. Create an architecture, analyze its cost, and compare the cost with the project 1
2. Using the AWS management console, implement the architecture. **Note:** you dont need to create the domain and SSL certificate

## Task 2 - Backend - ALB + Lambda

In order to support the backend logic for payments, your team decides to host the logic in a lambda. There are two typical internet-facing components that can be used in front of a lambda: AWS Application Load Balancer (ALB) and AWS API Gateway. Normally, you would use an API Gateway to create a backend RESTful interface. However, you found limitations on it and you decide to use an ALB that is directing the traffic directly to the payment logic. In this task you have to:

1. Create an architecture and compare the costs with the architecture of the project 1
2. Create a python 3 lambda function
2. Create an application load balancer
3. Configure the lambda and ALB so that request sent to the ALB are sent to the lambda function. You can use the following code for the lambda function:

```
import json

import logging
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    logger.info("received event")
    logger.info(event)
    logger.info(context)

    body = {
        "paymentApproved": True
    }

    response = {
                    "isBase64Encoded": False,
                    "statusCode": 200,
                    "statusDescription": "200 OK",
                    "headers": {
                        "Content-Type": "application/json"
                    },
                    "body": json.dumps(body)
                }
    return response

```
> Note: as mentioned before, you would typically implement this using an AWS API Gateway that triggers a lambda. However, the lab environment restricts using AWS API Gateway. If you want to try it on your own, you can use the openAPI spec `my-store-openapi.yaml` in your own AWS account (outside of the lab environment)

## Optional (10 extra points)- Task 3 - Infrastructure as Code

Develop the solution with infrastructure as code using terraform, cloudformation, or CDK.



https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build

export AWS_ACCESS_KEY_ID=