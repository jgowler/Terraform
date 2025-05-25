# Terraform VPN Deployment  

This Terraform configuration automates the deployment of a **Virtual Private Network (VPN) infrastructure** in **Azure**, ensuring secure connectivity between on-premises and cloud environments.

**Important Note:** All **sensitive information** such as credentials, subscription IDs, and access keys should be stored in the `variables.tf` file. This file is **not included** in any Terraform configurations present in this repository, ensuring security and preventing accidental exposure.

## Current Projects  

### VPN Resource Group  
Creates an **isolated resource group** for VPN-related services:  
- **Name:** `vpn-rg`  
- **Location:** Defined via a variable  

### Virtual Network and Subnet  
Establishes the **VPN VNet** and the **GatewaySubnet** for VPN traffic:  
- **VNet Name:** `VNET-VPN`  
- **Address Space:** `10.2.0.0/16`  
- **Subnet Name:** `GatewaySubnet`  
- **Subnet Range:** `10.2.0.0/24`  

### VPN Gateway and Public IP  
Deploys the **VPN Gateway** with required configurations:  
- **Public IP:** Static allocation for secure access  
- **VPN Type:** Route-based (IPsec)  
- **Private IP Allocation:** Dynamic  
- **BGP Enabled:** Disabled  

### Local Network Gateway  
Defines the **on-premises gateway** for site-to-site connectivity:  
- **Name:** `vpngw-local-site1`  
- **Gateway Address:** Defined via a variable  
- **Local Address Space:** Configurable  

### VPN Connection  
Establishes a **secure IPsec connection** between Azure and on-premises environments:  
- **Protocol:** IKEv2  
- **Encryption:** Uses a **randomly generated shared key**  
- **Dependencies:** Ensures gateway configurations are applied first  