#!/bin/sh
# This script will monitor another HA node and take over a Virtual IP (VIP)
# if communication with the other node fails.
# Based on:
#     https://aws.amazon.com/articles/2127188135977316
# Azure implementation relies on the MultipleIPsPerNic feature being turned ON. Details here:
#     https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-cli

# High Availability IP variables: *** CHANGE FOR EACH NODE ***
#     HA_Node_Private_IP: Other node's IP to ping. VIP public IP name 
#     HA_Node_NIC_Name: Other node's NIC name.
#     NIC_Name: This node's NIC name.
HA_Node_Private_IP=10.6.0.11
HA_Node_NIC_Name=ha-node1-nic
NIC_Name=ha-node2-nic

# Common High Availability IP variables:
#     Resource_Group: Azure resource group in which the resources are.
#     VIP_Private_IP: VIP private IP to swap if other node goes down.
#     VIP_Public_IP_Name: Resource name of the VIP Public IP.
Resource_Group=HA-rg
VIP_Private_IP=10.6.0.10
VIP_Public_IP_Name=ha-vip-ip

# Azure Active Directory (AAD) Service Principal Name (SPN) variables:
# NOTE: You get this information from the create SPN call:
#       e.g.: az ad sp create-for-rbac -n "http://aad-ha-demo-app" --role contributor --scopes "/subscriptions/ff001122-1111-4321-1234-aabbccddeeff/resourceGroups/HA-rg"
Service_Principal_Name="http://aad-ha-demo-app"
Service_Principal_Password=aabbccdd-eeff-1122-3344-112233445566
TenantId=ffeeddcc-bbaa-9988-7766-554433221100

# Login to Azure with the Service Principal credentials:
#     More info on SP's in Azure and how to create them:
#     https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal-cli
# (Note: This depends on V2 of the Azure CLI. See: https://github.com/Azure/azure-cli)
az login --service-principal -u $Service_Principal_Name -p $Service_Principal_Password --tenant $TenantId

echo `date` "-- Starting HA monitor"
while [ . ]; do
  pingresult=`ping -c 3 -W 1 $HA_Node_Private_IP | grep time= | wc -l`
  if [ "$pingresult" = "0" ]; then
    echo `date` "-- HA heartbeat failed, taking over VIP"
    
    # Update the NIC's secondary IP addess IP configuration to point to the VIP Public IP addess:
    # 1) Delete the IP config from the other HA node: ()
    az network nic ip-config delete -n ipconfig-float --nic-name $HA_Node_NIC_Name -g $Resource_Group

    # 2) Create an secondary IP config for this NIC and associate with the VIP public IP address: 
    az network nic ip-config create -n ipconfig-float --nic-name $NIC_Name -g $Resource_Group --private-ip-address $VIP_Private_IP --private-ip-address-allocation Static --public-ip-address $VIP_Public_IP_Name

    pingresult=`ping -c 1 -W 1 $VIP_Private_IP | grep time= | wc -l`
    if [ "$pingresult" = "0" ]; then
      echo `date` "-- Restarting network"

      # Ubuntu: Update the network table and restart network interface:
      # 1) Add the second private ip address to the network interface configuration file:
      #    /etc/network/interfaces.d/eth0.cfg
      # Add line: iface eth0 inet static
      # Add line: address $VIP_Private_IP
      echo "iface eth0 inet static" >> /etc/network/interfaces.d/eth0.cfg && echo "address $VIP_Private_IP" >> /etc/network/interfaces.d/eth0.cfg

      # 2) Reset the network interface:
      ifdown eth0 > /dev/null 2>&1 && ifup eth0 > /dev/null 2>&1
    fi
    sleep 60
  fi
  sleep 2
done