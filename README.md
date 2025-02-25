

# Azure Automation & Infrastructure Collection

This repository contains a collection of scripts and Terraform configurations that demonstrate various Azure automation tasks and infrastructure deployments. The content covers a wide range of topics, including:

- **Virtual Machine & Networking Provisioning:**  
  Create and manage resource groups, virtual networks, subnets, public IPs, network security groups, and virtual machines using both PowerShell (Az module) and Terraform.

- **Load Balancing & Connectivity Testing:**  
  Configure load balancing for highly available VMs, set up network watchers, and run connectivity tests (IP flow verification) to validate network security configurations.

- **Storage & Azure Files:**  
  Create storage accounts, containers, and manage blobs (upload/download) using PowerShell commands.

- **Key Vault, Certificates, and Secure Web Apps:**  
  Provision Azure Key Vaults, generate and store certificates, and deploy secure web applications with custom script extensions that configure IIS.

- **Azure AD & Role-Based Access Control (RBAC):**  
  Manage Azure AD users, groups, applications, and service principals, assign licenses, create dynamic groups, and handle custom role assignments with both the AzureAD and Microsoft Graph modules.

- **Backup, Recovery, and Maintenance:**  
  Automate backup and recovery operations, manage Azure Backup items, and perform maintenance tasks on virtual machines.

- **Azure Management Groups & Policies:**  
  Create and manage management groups, as well as assign policies across your Azure environment.

- **Microsoft Graph Integration:**  
  Query and manage Microsoft Graph objects (e.g., users, service principals) using the Microsoft Graph PowerShell module.

- **Terraform Integrations:**  
  Examples of declarative infrastructure provisioning and external operations (e.g., invoking CLI commands for tasks not natively supported by Terraform).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Usage](#usage)
  - [Running PowerShell Scripts](#running-powershell-scripts)
  - [Terraform Configurations](#terraform-configurations)
- [Contributing](#contributing)
- [License](#license)
- [Disclaimer](#disclaimer)

## Prerequisites

- **Azure Subscription:**  
  Ensure you have an active Azure subscription with the necessary permissions for resource creation and management.
- **PowerShell Modules:**  
  - [Az](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)  
  - [AzureAD](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2) or [AzureADPreview](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2)  
  - [Microsoft.Graph](https://learn.microsoft.com/en-us/graph/powershell/installation)
- **Terraform:**  
  Install Terraform (version 0.15 or later is recommended).
- **Azure CLI:**  
  Some tasks (e.g., blob downloads via external scripts) require the Azure CLI.

## Repository Structure

```
├── PowerShell
│   ├── azure-vm-provisioning.ps1
│   ├── azure-load-balancer.ps1
│   ├── azure-file-storage.ps1
│   ├── azure-ad-automation.ps1
│   ├── azure-rbac-assignments.ps1
│   ├── keyvault-cert-secure-web.ps1
│   ├── ad-ds-installation.ps1
│   ├── backup-recovery-maintenance.ps1
│   ├── graph-queries.ps1
│   └── ... (other scripts)
├── Terraform
│   ├── vm-networking.tf
│   ├── keyvault-certificate.tf
│   ├── ad-ds.tf
│   ├── app-service.tf
│   ├── management-groups.tf
│   └── ... (other configurations)
├── get_laps.ps1                # Example external script for Graph queries (if needed)
├── README.md
└── LICENSE
```

## Usage

### Running PowerShell Scripts

1. **Open PowerShell or Azure Cloud Shell.**
2. **Run the scripts:**  
   Each script is self-contained. For example, to provision a VM with AD DS, run:
   ```powershell
   .\PowerShell\ad-ds-installation.ps1
   ```
3. **Authentication:**  
   Ensure you run `Connect-AzAccount` or `Connect-AzureAD` as required by each script.

### Terraform Configurations

1. **Navigate to the Terraform directory:**
   ```powershell
   cd Terraform
   ```
2. **Initialize Terraform:**
   ```bash
   terraform init
   ```
3. **Plan the Deployment:**
   ```bash
   terraform plan
   ```
4. **Apply the Configuration:**
   ```bash
   terraform apply
   ```
5. **Cleanup:**
   When finished, run:
   ```bash
   terraform destroy
   ```

## Contributing

Contributions, bug fixes, and enhancements are welcome. Please follow these steps:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes and push to your branch.
4. Open a pull request describing your changes.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## Disclaimer

This repository is provided "as is" without warranty of any kind. Use it at your own risk. Ensure you understand and test any scripts or configurations before deploying them in a production environment.
