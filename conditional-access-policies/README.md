# Terraform Conditional Access Policies  

This Terraform configuration automates the deployment of **Azure AD Conditional Access Policies**, ensuring security controls for authentication and access management.

**Important Note:** All **sensitive information** such as credentials, subscription IDs, and access keys should be stored in the `variables.tf` file. This file is **not included** in any Terraform configurations present in this repository, ensuring security and preventing accidental exposure.

## Policies:  

### Allowed Countries Policy  
A **location-based access restriction** that blocks sign-ins from unauthorized regions:  
- **Client Applications:** Applied to all client apps  
- **Applications:** Includes all Azure AD apps  
- **Locations:** Blocks sign-ins from any country except the allowed list  
- **Platforms:** Applies to all device platforms  
- **Users:** Enforced for all users  
- **Grant Controls:** Restricts access using a block policy  

### AVD - Prompt for Multi-Factor Authentication (MFA)  
An **identity protection policy** ensuring enhanced security for **Azure Virtual Desktop (AVD)** and related applications:  
- **Client Applications:** Applies to browser and desktop clients  
- **Risk Levels:** Targets sign-ins and users classified as medium risk  
- **Applications:** Covers Azure Virtual Desktop, Microsoft Remote Desktop, and Windows Cloud Login  
- **Users:** Enforces policy on all groups  
- **Grant Controls:** Requires **MFA** or blocks access  
- **Session Controls:** Requires reauthentication every **hour**  

### Named Location - Allowed Countries  
Defines **trusted geographic regions** for conditional access enforcement:  
- **Location Name:** Allowed Countries  
- **Regions:** Limits sign-ins to **United Kingdom (GB)**  
- **Unknown Regions:** Explicitly denied  