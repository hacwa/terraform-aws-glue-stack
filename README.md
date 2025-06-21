## Things Left To Do

- Document requesting admin access to install Chocolatey
- Find and document Phoenix IP range (then restrict RDS access to it)
- Once IP is known, make this repo private or move it to an internal Cap repo


---
### Note: Project Name Prefix

This project uses a **project name prefix** to name all key resources:

- the Glue job
- the RDS database
- the S3 bucket
- IAM roles, and more

This is controlled by the `project` variable in `variables.tf`:

variable "project" {
  description = "Tag / resource name prefix"
  type        = string
}

Since there’s **no default**, Terraform will prompt you for a value during `terraform apply`.

Choose a short-ish, lowercase name like `oddment`, `timeywimey`, or `projectx`.
This value will be prepended to resource names (e.g., `timeywimey-glue-job`, `timeywimey-glue-mysql`, `timeywimey-glue-bucket`, etc.).

**Important:**
This prefix is also used to name the S3 bucket, which must be **globally unique across all AWS accounts worldwide**.
If Terraform fails due to a bucket name conflict, try a more unique prefix like `timeywimey-20250621` or include your initials.


## Install prerequisites on Windows using PowerShell

1. Open PowerShell as Administrator (right-click and choose "Run as administrator").

2. Install Chocolatey:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = `
[System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

3. Exit the shell and reopen PowerShell as Administrator.

4. Install required tools:

```powershell
choco install terraform
```

```powershell
choco install awscli
```

```powershell
choco install git.install
```

## Step 1 – Create an AWS Account

Go to https://aws.amazon.com and sign up if you don't already have an account.

If you already have access through Indy, sign in using SSO.
Once signed in, select **"Access Keys"** when presented with environment options —
you’ll use those credentials in Step 4.

## Step 2 - Create an IAM User with Permissions

- Go to IAM > Users > Create user
- Under "Set permissions", choose "Attach policies directly"
- Click "Create policy" (opens in a new tab)
- Switch to the JSON tab
- Paste in the contents of IAM-permission-policies.json
- Click Next, name the policy, and click Create policy
- Back in the user creation tab, refresh the policy list
- Select your new policy and complete user creation

## Step 3 - Create Access Keys

- Go to IAM > Users > [your new user]
- Go to the "Security credentials" tab
- Click "Create access key"
- Choose "Command Line Interface (CLI)" as the use case
- Tick the confirmation box and click Next
- Click "Create access key" and copy or download the keys

## Step 4 – Add AWS Credentials in PowerShell (Windows)

You have two options for setting AWS credentials:

    ### Option 1 – Persistent (recommended)
    1. Create or edit this file:
    C:\Users\<YourUsername>\.aws\credentials

    2. Add the following content (replace with your actual keys):

    [default]
    aws_access_key_id = YOUR_ACCESS_KEY_ID
    aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

    3. Set the default region (PowerShell):
    aws configure set region eu-west-1

    This creates or updates:
    C:\Users\<YourUsername>\.aws\config

---

### Option 2 – Temporary (current session only)

    In PowerShell, run:

    $env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
    $env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
    $env:AWS_DEFAULT_REGION = "eu-west-1"

    These environment variables will be lost when the shell is closed.


## Step 5 – Clone and Deploy

```powershell
git clone https://github.com/hacwa/terraform-aws-glue-stack.git
```

```powershell
cd terraform-aws-glue-stack
```

```powershell
terraform init
```

```powershell
terraform apply --auto-approve
```


---

### Important: Note the `db_endpoint` Output

Once the deployment finishes, Terraform will display several outputs — **the only one you need to take note of is:**

- `db_endpoint`

Use this value as the **Server** field when connecting in Power BI.
Make sure the value ends with `:3306`, for example:
```powershell
xxxx-xxxxx-xxxxx.xxxxxxxxax.eu-west-1.rds.amazonaws.com:3306
This is the hostname and port of your MySQL database.
```
## Step 6 - Create and Upload Test Data

```powershell
$BUCKET = terraform output -raw bucket_name
```

```powershell
"id,name`n1,Alice`n2,Bob" | Out-File -Encoding ASCII -FilePath $env:TEMP\demo.csv
```

```powershell
aws s3 cp "$env:TEMP\demo.csv" "s3://$BUCKET/raw/demo.csv"
```


## Step 7 - Run Glue Job

```powershell
$PROJECT = terraform output -raw project
aws glue start-job-run --job-name "$PROJECT-glue-transform"
```

## Step 8 - Get RDS Credentials for Power BI

```powershell
terraform output -raw rds_username
```

```powershell
terraform output -raw rds_password
```


## Step 9 - Configure Power BI Desktop

- Open Power BI Desktop
- Choose MySQL as a data source
- Enter the RDS endpoint from: terraform output -raw db_endpoint
- Use the credentials from Step 8

## Step 10 - Tear Down

```powershell
terraform destroy --auto-approve
```
