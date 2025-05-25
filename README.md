# Terraform Azure Deployments  

This repository contains **Terraform configurations** designed to automate deployments in **Microsoft Azure**, streamlining **infrastructure provisioning**, enforcing best practices, and enabling **scalable cloud architectures**.

**Important Note:** All **sensitive information** such as credentials, subscription IDs, and access keys should be stored in the `variables.tf` file. This file is **not included** in any Terraform configurations present in this repository, ensuring security and preventing accidental exposure.

## Current Projects  

### Hub-and-Spoke Network  
A **secure network design** that enhances connectivity and segmentation through:  
- **Azure Firewall** for centralized security policy enforcement  
- **VNet peering** to establish efficient spoke network communication  
- **Network Security Groups (NSGs)** for granular traffic segmentation and routing  

### Azure Active Directory Domain Services (AADDS)  
A **fully automated setup** for deploying **Azure AD Domain Services**, ensuring identity management and secure authentication:  
- **Provider registration checks** to streamline AADDS integration  
- **Service principal provisioning** to manage domain authentication  
- **Virtual network and security configuration** for seamless domain connectivity  
- **Automatic admin account and password generation** for secure access  

### Storage Account and File Shares  
A **scalable storage solution** that provisions an Azure Storage Account with managed file shares:  
- **Automated storage account creation** with dynamic naming  
- **Secure configurations**, including TLS1.2 and large file share support  
- **Provisioning of FileShare1 and FileShare2**, each with defined quota limits  

### Conditional Access Policies  
A **security framework** that strengthens identity and access controls across **Azure AD**:  
- **Allowed Countries Policy:** Restricts authentication to specific geographic locations  
- **AVD MFA Policy:** Requires multi-factor authentication for high-risk Azure Virtual Desktop sign-ins  
- **Named Location Configuration:** Defines trusted country-based access rules  