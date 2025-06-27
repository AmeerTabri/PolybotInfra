import boto3
import os
from datetime import datetime, timedelta

REGION = "us-west-2"
SSM_PARAM = "/k8s/worker/join-command"
INSTANCE_ID = os.environ["CONTROL_PLANE_INSTANCE_ID"]  # Pass this as an env var to Lambda

ssm = boto3.client("ssm", region_name=REGION)

def lambda_handler(event, context):
    print("✅ Lambda triggered by SNS")
    try:
        param = ssm.get_parameter(Name=SSM_PARAM, WithDecryption=True)
        value = param["Parameter"]["Value"]
        timestamp = param["Parameter"]["LastModifiedDate"]
        print("🧪 Current token:", value)
        print("⏱️ Last updated:", timestamp)

        if (datetime.now(timestamp.tzinfo) - timestamp) > timedelta(hours=23):
            print("🔁 Token expired — generating a new one")
            generate_new_token()
        else:
            print("✅ Token is still valid")

    except ssm.exceptions.ParameterNotFound:
        print("❌ Token parameter not found — generating a new one")
        generate_new_token()

    return {"statusCode": 200}


def generate_new_token():
    ssm_cmd = "kubeadm token create --print-join-command"
    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [ssm_cmd]},
    )
    command_id = response["Command"]["CommandId"]

    # Wait for the command to finish
    waiter = ssm.get_waiter("command_executed")
    waiter.wait(CommandId=command_id, InstanceId=INSTANCE_ID)

    # Get output
    output = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=INSTANCE_ID,
    )
    join_cmd = output["StandardOutputContent"].strip()
    print("📦 New join command:", join_cmd)

    # Push to SSM
    ssm.put_parameter(
        Name=SSM_PARAM,
        Value=join_cmd,
        Type="SecureString",
        Overwrite=True
    )
    print("✅ New join command saved to SSM")
