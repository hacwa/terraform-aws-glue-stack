## things left to do

Find a way to deploy this on a locked down windows laptop
add steps how to configure power BI
find out and add phoenix IP range ( then make this private or move somewhere internally)
steps to tear down




# Prerequisites

Make sure you have:

- A terminal with bash or zsh
- AWS CLI installed
- Terraform installed

# Step 1 - Create an AWS Account

Go to https://aws.amazon.com and sign up if you don't already have an account.

# Step 2 - Create an IAM User with Permissions

- Go to IAM > Users > Create user
- Under "Set permissions", choose "Attach policies directly"
- Click "Create policy" (opens in a new tab)
- Switch to the "JSON" tab
- Paste the contents of IAM-permission-policies.json over the default content
- Click "Next"
- Name the policy and click "Create policy"
- Back in the user creation tab, refresh the policy list
- Search for your new policy, select it, and complete user creation

# Step 3 - Create Access Keys

- Go to IAM > Users > select your new user
- Go to the "Security credentials" tab
- Click "Create access key"
- Choose "Command Line Interface (CLI)" as the use case
- Tick the confirmation box and click "Next"
- Click "Create access key" and copy or download the keys

# Step 4 - Add AWS Credentials

Edit or create this file: ~/.aws/credentials

Example:

[default]
aws_access_key_id = AKIAxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxx

Set the default region to eu-west-1:

aws configure set region eu-west-1

# Step 5 - Clone and Deploy

git clone https://github.com/hacwa/terraform-aws-glue-stack.git
cd terraform-aws-glue-stack
terraform init
terraform apply --auto-approve



# Step 6 - Create and upload Test Data

export BUCKET=$(terraform output -raw bucket_name)

printf 'id,name\n1,Alice\n2,Bob\n' > /tmp/demo.csv

aws s3 cp /tmp/demo.csv "s3://$BUCKET/raw/demo.csv"

# Step 7 - Run Glue Job

aws glue start-job-run --job-name wex8-glue-transform

# Step  - pbtain creds for Power BI

terraform output -raw rds_username && \
terraform output -raw rds_password


# Step  - Tear down
terraform apply --auto-approve
