import boto3
from datetime import datetime, timedelta
import os
import json

# Initialize boto3 clients
# Cost Explorer is only in us-east-1, regardless of your region
ce_client = boto3.client('ce', region_name='us-east-1')
ses_client = boto3.client('ses', region_name='us-east-1')

# Get configuration from environment variables
try:
    SENDER_EMAIL = os.environ['SENDER_EMAIL']
    RECIPIENT_EMAIL = os.environ['RECIPIENT_EMAIL']
except KeyError as e:
    print(f"Error: Environment variable {e} not set.")
    raise

def lambda_handler(event, context):
    """
    Lambda handler function to generate and email a daily AWS cost report
    grouped by the 'Environment' tag.
    """
    
    # Get yesterday's date range. Cost Explorer data can be delayed.
    end_date = datetime.now().strftime('%Y-%m-%d')
    start_date = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

    print(f"Fetching cost data from {start_date} to {end_date}")

    try:
        # Get cost and usage data grouped by the 'Environment' tag
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'TAG',
                    'Key': 'Environment'
                }
            ]
        )

        # --- Build the Email Report ---
        report = f"AWS Cost Report for {start_date}\n\n"
        report += "--------------------------------------\n"
        total_cost = 0.0

        if not response['ResultsByTime'][0]['Groups']:
            report += "No cost data found for this period.\n"
        else:
            for result in response['ResultsByTime'][0]['Groups']:
                # Tag keys are in the format 'Environment$Value'
                # If the key is just '$', it means the resource is untagged.
                env_key = result['Keys'][0]
                if env_key == 'Environment$':
                    env = 'Untagged'
                else:
                    env = env_key.split('$')[1] if '$' in env_key else 'Untagged'
                    
                amount = float(result['Metrics']['UnblendedCost']['Amount'])
                total_cost += amount
                report += f"- Environment: {env:<15} | Cost: ${amount:.4f}\n"

        report += "--------------------------------------\n"
        report += f"Total Cost: ${total_cost:.4f}\n"

        print(f"Report generated:\n{report}")

        # --- Send the Email via SES ---
        ses_client.send_email(
            Source=SENDER_EMAIL,
            Destination={'ToAddresses': [RECIPIENT_EMAIL]},
            Message={
                'Subject': {'Data': f'Daily AWS Cost Report - {start_date}'},
                'Body': {'Text': {'Data': report}}
            }
        )
        
        print("Report successfully sent via SES.")
        return {
            'statusCode': 200,
            'body': json.dumps('Report sent successfully!')
        }

    except ce_client.exceptions.DataUnavailableException:
        print("Cost data is not yet available. No report sent.")
        return {
            'statusCode': 200,
            'body': json.dumps('Cost data not yet available.')
        }
    except Exception as e:
        print(f"Error: {e}")
        # Optionally, send an error notification to the admin
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error generating report: {str(e)}')
        }