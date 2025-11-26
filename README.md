### Jenkins & AWS Credentials Setup Guide

This guide provides the required steps to configure passwordless sudo for the Jenkins user and securely store AWS credentials inside Jenkins.

🔧 1. Configure Jenkins for Passwordless Sudo

To allow Jenkins to execute sudo commands without requiring a password:

### ✔ Step 1 — Edit the Sudoers File

Run the following command on your Jenkins server:

```bash
sudo visudo
```

### ✔ Step 2 — Add Jenkins User to Passwordless Sudo

Add this line at the bottom of the file:

```bash
jenkins ALL=(ALL) NOPASSWD:ALL
```

Save and exit.

### 🔐 2. Add AWS Credentials in Jenkins

Navigate to:

Jenkins Dashboard → Manage Jenkins → Manage Credentials → Global → Add Credentials

### Add the following two credentials:

### 1️⃣ AWS_ACCESS_KEY_ID

Kind: Secret Text

ID: AWS_ACCESS_KEY_ID

Value:

AKIAxxxxxxxxxx

### 2️⃣ AWS_SECRET_ACCESS_KEY

Kind: Secret Text

ID: AWS_SECRET_ACCESS_KEY

Value:

xxxxxxxxxxxxxxxxxxxxxxxx
