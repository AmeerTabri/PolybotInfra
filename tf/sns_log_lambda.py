import boto3
import os
from datetime import datetime, timedelta

ssm = boto3.client("ssm", region_name="us-west-2")

def lambda_handler(event, context):
    print("✅ Lambda triggered by SNS")
    try:
        param = ssm.get_parameter(Name="/k8s/worker/join-command", WithDecryption=True)
        value = param["Parameter"]["Value"]
        timestamp = param["Parameter"]["LastModifiedDate"]
        print("🧪 Current token:", value)
        print("⏱️ Last updated:", timestamp)

        # Simple expiration check
        if (datetime.now(timestamp.tzinfo) - timestamp) > timedelta(hours=23):
            print("🔁 Token expired — should generate a new one")
            # Placeholder: In production, call SSM RunCommand or SSH to control-plane
        else:
            print("✅ Token is still valid")

    except ssm.exceptions.ParameterNotFound:
        print("❌ Token parameter not found — should generate one")

    return {"statusCode": 200}
