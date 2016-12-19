# Azure-Floating-IP
## What is a Floating IP, and why should I even care?
In a nutshell, a Floating IP is an IP address that can be moved from a primary VM to a standby VM when the primary VM fails.
According to the [Floating IP Pattern](http://en.clouddesignpattern.org/index.php/CDP:Floating_IP_Pattern) wiki, the problem is:
> You need to stop the server when applying a patch to a server, or when upgrading the server (to increase the processing capabilities). Because stopping a server stops the services it provides, you need to to minimize the downtime.

> For web servers, you can use the Domain Name System (DNS) to swap the server. However, in this case as well, typically the swapping time cannot be shortened to less than the Time to Live (TTL) value, so this is not suited to instant swapping.

It is worth noting that I am referencing material from AWS docs. That's because Azure did not have real support for Floating IP addresses. In fact, the Azure Load Balancer supported a similar concept known as Direct Server Return (DSR), which is leveraged, for example, by Microsoft SQL Server AlwaysOn Availability Groups. Unfortunately, the setting is deceptively named enableFloatingIP in the [Azure REST APIs](https://msdn.microsoft.com/en-us/library/mt163574.aspx):
> loadBalancingRules.**enableFloatingIP**

> Floating IP is pertinent to failover scenarios: a “floating” IP is reassigned to a secondary server in case the primary server fails. Floating IP is required for SQL AlwaysOn.

The DSR setting is set on the Azure Load Balancer on the Azure portal as shown below:
![DSR setting on the Azure Load Balancer in the Azure Portal](https://github.com/StratusOn/Azure-Floating-IP/blob/master/images/AzureLoadBalancer-DSR1.jpg "DSR setting on the Azure Load Balancer in the Azure Portal")

> Note how the help tooltip of the DSR clearly indicates its capabilities and limitations:
>
> ![DSR setting on the Azure Load Balancer in the Azure Portal Help Tooltip](https://github.com/StratusOn/Azure-Floating-IP/blob/master/images/AzureLoadBalancer-DSR2.jpg "DSR setting on the Azure Load Balancer in the Azure Portal Help Tooltip")

## Why now?
A new Azure Networking feature called [MultipleIPsPerNic](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-portal) has made it to Azure! Armed with this feature, you can now easily implement the Floating IP pattern in Azure. Now we're talking!
> **NOTE:** The MultipleIPsPerNic is currently in preview and available in only a subset of the Azure regions. That also means it's not bound by an SLA or supportability. Once it becomes GA, it should become available in all Azure regions with the normal Azure SLAs.

> The following exceprt from the [documentation page](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-portal) explains the steps needed to get your Azure subscription whitelisted in order to use this feature:

> Register for the preview by sending an email to [Multiple IPs](mailto:MultipleIPsPreview@microsoft.com?subject=Request to enable subscription <subscription id>>) with your subscription ID and intended use. Do not attempt to complete the remaining steps:

>  * Until you receive an e-mail notifying you that you've been accepted into the preview

>  * Without following the instructions in the email you receive

## How-To: Setup & Configuration
### The Manual Method
The following steps describe how to take the 2 script files found under the "ubuntu" folder in this repo and configure them on the 2 nodes against which you wish to setup active/standby HA using the Floating IP pattern.

> The following steps assume that you already have 2 ubuntu VM's created and running and that they are in a resource group named "HA-rg". You may of course change the name to match that of your resource group.

1. Create a Service Principal and give it "contributor" access to your resource group. For example, you can do that using [Azure CLI v2](https://github.com/Azure/azure-cli) as follows:

  > **az** **ad** **sp** **create-for-rbac** -**n** "http://aad-ha-demo-app" --**role** contributor --**scopes** "/subscriptions/ff001122-1111-4321-1234-aabbccddeeff/resourceGroups/HA-rg"

  where:
  * **http://aad-ha-demo-app:** The service principal name; it can be anything you choose.
  * **ff001122-1111-4321-1234-aabbccddeeff:** Replace with your own subscription id.
  * **HA-rg:** Replace with your own resource group name.

  Take note of the following pieces of information in the resulting JSON – you’ll need to plug their values in the script:
  * **name**
  * **password**
  * **tenant**

2. On each VM, install the Azure CLI v2. See the instructions on this page: https://github.com/Azure/azure-cli

  > I'd highly recommend using the new Python-based Azure CLI versus the old Node.js-based Azure CLI available [here](https://github.com/Azure/azure-xplat-cli).
  
  > If you choose to use the old Azure Xplat CLI, you'd need to make changes in the scripts to replace the Azure CLI calls with those from the older version. Note though that the scripts have not been tested with the older CLI commands.

3. Download the script version for each node onto the corresponding VM and update the 9 variables at the top of the script to reflect your own environment and the AAD service principal information.

4. Test the scripts by inducing a failure scenario that triggers a failover and floating of the VIP from the primary node to the standby.
