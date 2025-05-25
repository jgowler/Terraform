# **Terraform Configuration for Azure Storage Account & File Shares**

## **Overview**
This Terraform configuration provisions an **Azure Storage Account** along with **two file shares**, ensuring secure storage with defined access controls.

---

## **1. Providers Configuration**
Defines required Terraform providers:
- **AzureRM**: Manages Azure resources.
- **AzureAD**: Interacts with Azure Active Directory.
- **Random**: Generates random values (e.g., storage account name).

Local backend storage for Terraform state is set at `./state/terraform.tfstate`.

---

## **2. Resource Group Creation**
Creates a resource group:
- **Name:** `strg_account_rg`
- **Location:** Defined via a variable.

---

## **3. Storage Account Setup**
Deploys an Azure Storage Account with:
- **Dynamically generated name** (`str_acc_<random_value>`).
- **Tier & Replication Type:** Configurable via variables.
- **Enabled Features:** TLS1.2, large file shares, shared access keys.

Tags ensure proper resource categorization.

---

## **4. File Share Creation**
Creates two storage file shares within the account:
- **FileShare1** - 100 GB quota.
- **FileShare2** - 100 GB quota.