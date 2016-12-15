# Azure-Floating-IP
## What is a Floating IP, and why should I even care?
In a nutshell, a Floating IP is an IP address that can be moved from a primary VM to a standby VM when the primary VM fails.
According to the [Floating IP Pattern](http://en.clouddesignpattern.org/index.php/CDP:Floating_IP_Pattern) wiki, the problem is:
> You need to stop the server when applying a patch to a server, or when upgrading the server (to increase the processing capabilities). Because stopping a server stops the services it provides, you need to to minimize the downtime.

> For web servers, you can use the Domain Name System (DNS) to swap the server. However, in this case as well, typically the swapping time cannot be shortened to less than the Time to Live (TTL) value, so this is not suited to instant swapping.

It is worth noting that I am referencing material from AWS docs. That's because Azure did not have real support for Floating IP addresses. In fact, the Azure Load Balancer supported a similar concept known as Direct Server Return (DSR), which is leveraged, for example, by Microsoft SQL Server AlwaysOn Availability Groups. Unfortunately, the setting is deceptively named enableFloatingIP in the [Azure REST APIs](https://msdn.microsoft.com/en-us/library/mt163574.aspx):
> loadBalancingRules.**enableFloatingIP**

> Floating IP is pertinent to failover scenarios: a “floating” IP is reassigned to a secondary server in case the primary server fails. Floating IP is required for SQL AlwaysOn.

## Why now?
A new Azure Networking feature called [MultipleIPsPerNic](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-portal) has made it to Azure! Armed with this feature, you can now easily implement the Floating IP pattern in Azure. Now we're talking!
> **NOTE:** The MultipleIPsPerNic is currently in preview and available in only a subset of the Azure regions. That also means it's not bound by an SLA or supportability. Once it becomes GA, it should become available in all Azure regions with the normal Azure SLAs.
