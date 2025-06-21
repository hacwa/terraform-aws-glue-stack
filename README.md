## Table of Contents

- [Things Left To Do](#things-left-to-do)
- [Project Name Prefix](#project-name-prefix)
- [Install Prerequisites Windows + PowerShell](#install-prerequisites-windows--powershell)
- [Step 1 - Create an AWS Account](#step-1---create-an-aws-account)
- [Step 2 - Add AWS Credentials in PowerShell](#step-2---add-aws-credentials-in-powershell)
- [Step 3 - Clone and Deploy](#step-3---clone-and-deploy)
- [Output to Note - db_endpoint](#output-to-note---db_endpoint)
- [Step 4 - Create and Upload Test Data](#step-4---create-and-upload-test-data)
- [Step 5 - Run Glue Job](#step-5---run-glue-job)
- [Step 6 - Get RDS Credentials](#step-6---get-rds-credentials)
- [Step 7 - Configure Power BI Desktop](#step-7---configure-power-bi-desktop)
- [Step 8 - Tear Down](#step-8---tear-down)

---

## Things Left To Do

- Document requesting admin access to install Chocolatey
- Find and document Phoenix IP range (then restrict RDS access to it)
- Once IP is known, make this repo private or move it to an internal Cap repo

---

## Project Name Prefix

This project uses a **project name prefix** to name all key resources:

- Glue job
- RDS database
- S3 bucket
- IAM roles


<details>
<summary>⚠️ Relying on prompt-based input (not recommended)</summary>

If you don’t specify the variable, Terraform will prompt you for it at apply time:

```powershell
terraform apply --auto-approve
```

This works, but makes automation and `destroy` less predictable.
</details>

**Recommended: set the project name explicitly for consistency and reuse**

```powershell
$PROJECT = "timeywimey20250621"
terraform apply --auto-approve -var "project=$PROJECT"
```

 Choose a short-ish, lowercase name like `oddment`, `timeywimey`, or `projectx`.
It will be prepended to all resource names like:

- `timeywimey20250621-glue-job`
- `timeywimey20250621-glue-mysql`
- `timeywimey20250621-glue-bucket`

**Important:**
This prefix is used to name the **S3 bucket**, which must be **globally unique across all AWS accounts**.
If Terraform fails due to a name conflict, try a more specific prefix like `timeywimeyoddishexecutor20250621` or add your initials.

---

## Install Prerequisites Windows + PowerShell

1. **Open PowerShell as Administrator**

2. **Install Chocolatey**:

    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    ```

3. **Close and reopen PowerShell as Administrator**

4. **Install required tools**:

    ```powershell
    choco install terraform
    ```

    ```powershell
    choco install awscli
    ```

    ```powershell
    choco install git.install
    ```

---

## Step 1 - Create an AWS Account

Go to [https://aws.amazon.com](https://aws.amazon.com) and sign up if needed.

If you have access from **Indy**, sign in.
When choosing an account, select **"Access Keys"**  > Powershell — you’ll use those in Step 2.

---

## Step 2 - Add AWS Credentials in PowerShell

You have two options:

### Option 1 - Persistent

1. Create or edit this file:
   `C:\Users\<YourUsername>\.aws\credentials`

2. Add:

    ```
    [default]
    aws_access_key_id = YOUR_ACCESS_KEY_ID
    aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
    ```

3. Set default region:

    ```powershell
    aws configure set region eu-west-1
    ```

### Option 2 - Temporary (session-only)

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION = "eu-west-1"
```

---

## Step 3 - Clone with git and Deploy with terraform

```powershell
git clone https://github.com/hacwa/terraform-aws-glue-stack.git
```

```powershell
cd terraform-aws-glue-stack
```

```powershell
terraform init
```

<details>
<summary> <code>terraform apply --auto-approve</code> (not recommended)</summary>

This will prompt for the `project` name interactively.
Only use this if you're testing manually and don’t need repeatability.

```powershell
terraform apply --auto-approve
```

</details>

 **Recommended: set the project name explicitly for repeatability and teardown support**

```powershell
$PROJECT = "timeywimey20250621"
terraform apply --auto-approve -var "project=$PROJECT"
```

---

## Output to Note - db_endpoint

After deploy, Terraform will print outputs.
**The one you need to take note of is:**

- `db_endpoint` → used as the **Server** field in Power BI

Ensure it ends in `:3306`, e.g.:

```powershell
xxxx-xxxxx-xxxxx.xxxxx.eu-west-1.rds.amazonaws.com:3306
```

---

## Step 4 - Create and Upload Test Data

```powershell
$PROJECT = terraform output -raw project
$BUCKET = terraform output -raw bucket_name
```

```powershell
"id,name`n1,Alice`n2,Bob" | Out-File -Encoding ASCII -FilePath "$env:TEMP\$PROJECT-demo.csv"
```

```powershell
aws s3 cp "$env:TEMP\$PROJECT-demo.csv" "s3://$BUCKET/raw/$PROJECT-demo.csv"
```

---

## Step 5 - Run Glue Job

```powershell
$PROJECT = terraform output -raw project
aws glue start-job-run --job-name "$PROJECT-glue-transform"
```

---

## Step 6 - Get RDS Credentials

```powershell
terraform output -raw rds_username
```

```powershell
terraform output -raw rds_password
```

---

## Step 7 - Configure Power BI Desktop

- Open Power BI Desktop
- Choose **MySQL** as the data source
- Use the RDS endpoint from `terraform output -raw db_endpoint`
- Use the credentials from Step 6

---

## Step 8 - Tear Down

```powershell
$PROJECT = terraform output -raw project
Write-Output "Destroying project: $PROJECT"
terraform destroy --auto-approve -var "project=$PROJECT"
```
