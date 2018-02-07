#!/bin/bash

## Bash Script to deploy an F5 ARM template into Azure, using azure cli 1.0 ##
## Example Command: ./deploy_via_bash.sh --licenseType PAYG --licensedBandwidth 200m --adminUsername azureuser --adminPassword <value> --dnsLabel <value> --instanceName f5vm01 --instanceType Standard_DS3_v2 --imageName Good --bigIpVersion 13.0.0300 --numberOfExternalIps 1 --vnetAddressPrefix 10.0 --enableNetworkFailover Yes --internalLoadBalancerType Per-protocol --internalLoadBalancerProbePort 3456 --ntpServer 0.pool.ntp.org --timeZone UTC --allowUsageAnalytics Yes --resourceGroupName <value> --azureLoginUser <value> --azureLoginPassword <value>

# Assign Script Parameters and Define Variables
# Specify static items below, change these as needed or make them parameters
region="westus"
restrictedSrcAddress="*"
tagValues='{"application":"APP","environment":"ENV","group":"GROUP","owner":"OWNER","cost":"COST"}'

# Parse the command line arguments, primarily checking full params as short params are just placeholders
while [[ $# -gt 1 ]]; do
    case "$1" in
        --resourceGroupName)
            resourceGroupName=$2
            shift 2;;
        --azureLoginUser)
            azureLoginUser=$2
            shift 2;;
        --azureLoginPassword)
            azureLoginPassword=$2
            shift 2;;
        --licenseType)
            licenseType=$2
            shift 2;;
        --licensedBandwidth)
            licensedBandwidth=$2
            shift 2;;
        --licenseKey1)
            licenseKey1=$2
            shift 2;;
        --licenseKey2)
            licenseKey2=$2
            shift 2;;
        --adminUsername)
            adminUsername=$2
            shift 2;;
        --adminPassword)
            adminPassword=$2
            shift 2;;
        --dnsLabel)
            dnsLabel=$2
            shift 2;;
        --instanceName)
            instanceName=$2
            shift 2;;
        --instanceType)
            instanceType=$2
            shift 2;;
        --imageName)
            imageName=$2
            shift 2;;
        --bigIpVersion)
            bigIpVersion=$2
            shift 2;;
        --numberOfExternalIps)
            numberOfExternalIps=$2
            shift 2;;
        --vnetAddressPrefix)
            vnetAddressPrefix=$2
            shift 2;;
        --enableNetworkFailover)
            enableNetworkFailover=$2
            shift 2;;
        --internalLoadBalancerType)
            internalLoadBalancerType=$2
            shift 2;;
        --internalLoadBalancerProbePort)
            internalLoadBalancerProbePort=$2
            shift 2;;
        --ntpServer)
            ntpServer=$2
            shift 2;;
        --timeZone)
            timeZone=$2
            shift 2;;
        --restrictedSrcAddress)
            restrictedSrcAddress=$2
            shift 2;;
        --tagValues)
            tagValues=$2
            shift 2;;
        --allowUsageAnalytics)
            allowUsageAnalytics=$2
            shift 2;;
        --)
            shift
            break;;
    esac
done

#If a required parameter is not passed, the script will prompt for it below
required_variables="adminUsername adminPassword dnsLabel instanceName instanceType imageName bigIpVersion numberOfExternalIps vnetAddressPrefix enableNetworkFailover internalLoadBalancerType internalLoadBalancerProbePort ntpServer timeZone allowUsageAnalytics resourceGroupName licenseType "
for variable in $required_variables
        do
        if [ -z ${!variable} ] ; then
                read -p "Please enter value for $variable:" $variable
        fi
done

# Prompt for license key if not supplied and BYOL is selected
if [ $licenseType == "BYOL" ]; then
    if [ -z $licenseKey1 ] ; then
            read -p "Please enter value for licenseKey1:" licenseKey1
    fi
    if [ -z $licenseKey2 ] ; then
            read -p "Please enter value for licenseKey2:" licenseKey2
    fi
    template_file="./BYOL/azuredeploy.json"
    parameter_file="./BYOL/azuredeploy.parameters.json"
fi
# Prompt for licensed bandwidth if not supplied and PAYG is selected
if [ $licenseType == "PAYG" ]; then
    if [ -z $licensedBandwidth ] ; then
            read -p "Please enter value for licensedBandwidth:" licensedBandwidth
    fi
    template_file="./PAYG/azuredeploy.json"
    parameter_file="./PAYG/azuredeploy.parameters.json"
fi
# Prompt for BIGIQ parameters if not supplied and BIGIQ is selected
if [ $licenseType == "BIGIQ" ]; then
	big_iq_vars="bigIqLicenseHost bigIqLicenseUsername bigIqLicensePassword bigIqLicensePool"
	for variable in $big_iq_vars
			do
			if [ -z ${!variable} ] ; then
					read -p "Please enter value for $variable:" $variable
			fi
	done
fi


echo "Disclaimer: Scripting to Deploy F5 Solution templates into Cloud Environments are provided as examples. They will be treated as best effort for issues that occur, feedback is encouraged."
sleep 3

# Login to Azure, for simplicity in this example using username and password supplied as script arguments --azureLoginUser and --azureLoginPassword
# Perform Check to see if already logged in
azure account show > /dev/null 2>&1
if [[ $? != 0 ]] ; then
        azure login -u $azureLoginUser -p $azureLoginPassword
fi

# Switch to ARM mode
azure config mode arm

# Create ARM Group
azure group create -n $resourceGroupName -l $region

# Deploy ARM Template, right now cannot specify parameter file AND parameters inline via Azure CLI,
if [ $licenseType == "BYOL" ]; then
    azure group deployment create -f $template_file -g $resourceGroupName -n $resourceGroupName -p "{\"adminUsername\":{\"value\":\"$adminUsername\"},\"adminPassword\":{\"value\":\"$adminPassword\"},\"dnsLabel\":{\"value\":\"$dnsLabel\"},\"instanceName\":{\"value\":\"$instanceName\"},\"instanceType\":{\"value\":\"$instanceType\"},\"imageName\":{\"value\":\"$imageName\"},\"bigIpVersion\":{\"value\":\"$bigIpVersion\"},\"numberOfExternalIps\":{\"value\":$numberOfExternalIps},\"vnetAddressPrefix\":{\"value\":\"$vnetAddressPrefix\"},\"enableNetworkFailover\":{\"value\":\"$enableNetworkFailover\"},\"internalLoadBalancerType\":{\"value\":\"$internalLoadBalancerType\"},\"internalLoadBalancerProbePort\":{\"value\":\"$internalLoadBalancerProbePort\"},\"ntpServer\":{\"value\":\"$ntpServer\"},\"timeZone\":{\"value\":\"$timeZone\"},\"restrictedSrcAddress\":{\"value\":\"$restrictedSrcAddress\"},\"tagValues\":{\"value\":$tagValues},\"allowUsageAnalytics\":{\"value\":\"$allowUsageAnalytics\"},\"licenseKey1\":{\"value\":\"$licenseKey1\"},\"licenseKey2\":{\"value\":\"$licenseKey2\"}}"
elif [ $licenseType == "PAYG" ]; then
    azure group deployment create -f $template_file -g $resourceGroupName -n $resourceGroupName -p "{\"adminUsername\":{\"value\":\"$adminUsername\"},\"adminPassword\":{\"value\":\"$adminPassword\"},\"dnsLabel\":{\"value\":\"$dnsLabel\"},\"instanceName\":{\"value\":\"$instanceName\"},\"instanceType\":{\"value\":\"$instanceType\"},\"imageName\":{\"value\":\"$imageName\"},\"bigIpVersion\":{\"value\":\"$bigIpVersion\"},\"numberOfExternalIps\":{\"value\":$numberOfExternalIps},\"vnetAddressPrefix\":{\"value\":\"$vnetAddressPrefix\"},\"enableNetworkFailover\":{\"value\":\"$enableNetworkFailover\"},\"internalLoadBalancerType\":{\"value\":\"$internalLoadBalancerType\"},\"internalLoadBalancerProbePort\":{\"value\":\"$internalLoadBalancerProbePort\"},\"ntpServer\":{\"value\":\"$ntpServer\"},\"timeZone\":{\"value\":\"$timeZone\"},\"restrictedSrcAddress\":{\"value\":\"$restrictedSrcAddress\"},\"tagValues\":{\"value\":$tagValues},\"allowUsageAnalytics\":{\"value\":\"$allowUsageAnalytics\"},\"licensedBandwidth\":{\"value\":\"$licensedBandwidth\"}}"
elif [ $licenseType == "BIGIQ" ]; then
    azure group deployment create -f $template_file -g $resourceGroupName -n $resourceGroupName -p "{\"adminUsername\":{\"value\":\"$adminUsername\"},\"adminPassword\":{\"value\":\"$adminPassword\"},\"dnsLabel\":{\"value\":\"$dnsLabel\"},\"instanceName\":{\"value\":\"$instanceName\"},\"instanceType\":{\"value\":\"$instanceType\"},\"imageName\":{\"value\":\"$imageName\"},\"bigIpVersion\":{\"value\":\"$bigIpVersion\"},\"numberOfExternalIps\":{\"value\":$numberOfExternalIps},\"vnetAddressPrefix\":{\"value\":\"$vnetAddressPrefix\"},\"enableNetworkFailover\":{\"value\":\"$enableNetworkFailover\"},\"internalLoadBalancerType\":{\"value\":\"$internalLoadBalancerType\"},\"internalLoadBalancerProbePort\":{\"value\":\"$internalLoadBalancerProbePort\"},\"ntpServer\":{\"value\":\"$ntpServer\"},\"timeZone\":{\"value\":\"$timeZone\"},\"restrictedSrcAddress\":{\"value\":\"$restrictedSrcAddress\"},\"tagValues\":{\"value\":$tagValues},\"allowUsageAnalytics\":{\"value\":\"$allowUsageAnalytics\"},\"bigIqLicenseHost\":{\"value\":\"$bigIqLicenseHost\"},\"bigIqLicenseUsername\":{\"value\":\"$bigIqLicenseUsername\"}},\"bigIqLicensePassword\":{\"value\":\"$bigIqLicensePassword\"}},\"bigIqLicensePool\":{\"value\":\"$bigIqLicensePool\"}}"
else
    echo "Please select a valid license type of PAYG, BYOL or BIGIQ."
    exit 1
fi