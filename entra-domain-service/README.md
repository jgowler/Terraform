# **Terraform Configuration for Azure Active Directory Domain Services (AADDS)**

## **Overview**
This Terraform configuration automates the setup of **Azure Active Directory Domain Services (AADDS)**, including networking, security, and administrative roles.

---

## **1. Providers Configuration**
Defines required Terraform providers:
- **AzureRM**: Manages Azure resources.
- **AzureAD**: Interacts with Azure Active Directory.
- **Random**: Generates random data (e.g., passwords).

Local backend storage for Terraform state is set at `./state/terraform.tfstate`.

---

## **2. Microsoft.AAD Provider Registration**
Checks if the **Microsoft.AAD** provider is registered. If unregistered, it registers the provider to ensure AADDS functionality.

---

## **3. Service Principal Setup**
Ensures the required **Service Principal** exists before proceeding. If missing, Terraform creates it automatically or prompts you to import it.

---

## **4. Resource Group & Networking**
Creates a resource group and virtual network for AADDS:
- **VNet:** `VNET-AADDS`
- **Subnet:** `SUBNET-AADDS`
- **Network Security Group:** Allows RDP (`3389`) & PowerShell (`5986`).

---

## **5. Deploy Azure AD Domain Services**
Sets up **AADDS** with secure configurations:
- **Domain Name:** `aadds.example.com`
- **Password Sync:** Enables Kerberos, NTLM, and on-premise password synchronization.
- **Notifications:** Alerts domain & global admins.
- **Subnet Association:** Links AADDS to the designated subnet.

---

## **6. Administrator Account & Group**
Creates:
- **AADDS Admin User** (`AADDSAdmin@<domain>`)
- **AADDS Admin Group** (for management).

---

## **7. Secure Password Generation**
Generates a **64-character random password** for the admin user.

---

This Terraform setup automates AADDS provisioning efficiently, ensuring seamless security and network configuration.