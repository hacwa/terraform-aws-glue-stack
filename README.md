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

Controlled by the `project` variable in `variables.tf`:

```hcl
variable "project" {
  description = "Tag / resource name prefix"
  type        = string
}
```

Since there’s **no default**, Terraform will prompt you for a value during `terraform apply`.

Choose a short-ish, lowercase name like `oddment`, `timeywimey`, or `projectx`.
It will be prepended to resource names like `timeywimey-glue-job`, `timeywimey-glue-bucket`, etc.

**Important:**
This prefix is also used in the S3 bucket name, which must be **globally unique across all AWS accounts**.
If Terraform fails due to a name conflict, try `timeywimey-20250621` or include your initials.

---

# Install Prerequisites (Windows + PowerShell)

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

## Step 1 – Create an AWS Account

Go to [https://aws.amazon.com](https://aws.amazon.com) and sign up if needed.

If you have access from **Indy**, sign in using **SSO**.
When prompted, select **"Access Keys"** — you’ll use those in Step 4.

---

> Skip Steps 2 and 3 if using sandbox from Indy — you do **not** need to create an IAM user or generate access keys manually.

---

## Step 2 – Create an IAM User with Permissions

- Go to IAM > Users > Create user
- Under **Set permissions**, choose **Attach policies directly**
- Click **Create policy** → switch to the **JSON** tab
- Paste contents of `IAM-permission-policies.json`
- Click **Next**, name it, and click **Create policy**
- Back in the user creation tab, refresh and attach the new policy
- Complete user creation

---

## Step 3 – Create Access Keys

- IAM > Users > [your new user] > **Security credentials** tab
- Click **Create access key**
- Choose **Command Line Interface (CLI)**
- Confirm and create
- Copy or download the keys

---

## Step 4 – Add AWS Credentials in PowerShell

You have two options:

### Option 1 – Persistent

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

### Option 2 – Temporary (session-only)

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION = "eu-west-1"
```

---

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

### 🔎 Output to Note: `db_endpoint`

After deploy, Terraform will print outputs.
**The one you need is:**

- `db_endpoint` → used as the **Server** field in Power BI

Ensure it ends in `:3306`, e.g.:

```powershell
xxxx-xxxxx-xxxxx.xxxxx.eu-west-1.rds.amazonaws.com:3306
```

---

## Step 6 – Create and Upload Test Data

```powershell
$BUCKET = terraform output -raw bucket_name
```

```powershell
"id,name`n1,Alice`n2,Bob" | Out-File -Encoding ASCII -FilePath $env:TEMP\demo.csv
```

```powershell
aws s3 cp "$env:TEMP\demo.csv" "s3://$BUCKET/raw/demo.csv"
```

---

## Step 7 – Run Glue Job

```powershell
$PROJECT = terraform output -raw project
aws glue start-job-run --job-name "$PROJECT-glue-transform"
```

---

## Step 8 – Get RDS Credentials

```powershell
terraform output -raw rds_username
```

```powershell
terraform output -raw rds_password
```

---

## Step 9 – Configure Power BI Desktop

- Open Power BI Desktop
- Choose **MySQL** as the data source
- Use the RDS endpoint from `terraform output -raw db_endpoint`
- Use the credentials from Step 8

---

## Step 10 – Tear Down

```powershell
terraform destroy --auto-approve
```
