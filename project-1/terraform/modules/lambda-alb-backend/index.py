
import json
import logging
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    logger.info("received event")
    logger.info(event)
    logger.info(context)

    body = {"paymentApproved": True}

    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        "statusDescription": "200 OK",
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

