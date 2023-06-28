#Requires -Version 5.0

$FilePath   = "./dcr-sentinel-zpa-ama.json"
$ResourceId = "/subscriptions/{subscription}/resourceGroups/{resourcegroup}/providers/microsoft.insights/dataCollectionRules/{dataCollectionRuleName}"  

$selectOption = Read-Host -Prompt 'Select 1) To Create the ZPA_CL Table, 2) To download original Data Collection Rule (DCR) or 3) To upload the updated DCR'

if ($selectOption -eq '1') {

Connect-AzAccount -UseDeviceAuthentication
$tableParams = @'
{
"properties": {
    "schema": {
            "name": "ZPA_CL",
            "columns": [
                {
                    "name": "Computer",
                    "type": "String"
                },
                {
                    "name": "ManagementGroupName",
                    "type": "String"
                },
                {
                    "name": "RawData",
                    "type": "String"
                },
                {
                    "name": "SourceSystem",
                    "type": "String"
                },
                {
                    "name": "TimeGenerated",
                    "type": "DateTime"
                }, 
                {
                    "name": "Message",
                    "type": "String"
                }
            ]
    }
}
}
'@
Invoke-AzRestMethod -Path "/subscriptions/{subscription}/resourcegroups/{resourcegroup}/providers/microsoft.operationalinsights/workspaces/{workspace}/tables/ZPA_CL?api-version=2021-12-01-preview" -Method PUT -payload $tableParams

} elseif ($selectOption -eq '2') {

Connect-AzAccount -UseDeviceAuthentication
$DCR = Invoke-AzRestMethod -Path ("$ResourceId"+"?api-version=2021-09-01-preview") -Method GET
$DCR.Content | ConvertFrom-Json | ConvertTo-Json -Depth 20 | Out-File -FilePath $FilePath

} elseif ($selectOption -eq '3') {

Connect-AzAccount -UseDeviceAuthentication
$DCRContent = Get-Content $FilePath -Raw
$DCRContent = $DCRContent -replace '"transformKql": "source",','"transformKql": "source | where SyslogMessage has \"ZPA LSS Client\" | extend Message=SyslogMessage",'
$DCRContent = $DCRContent -replace '"outputStream": "Microsoft-Syslog"','"outputStream": "Custom-ZPA_CL"'
$DCRContent | Set-Content -Path './dcr-sentinel-zpa-ama.json'

#Invoke-AzRestMethod -Path ("$ResourceId"+"?api-version=2021-09-01-preview") -Method PUT -Payload $DCRContent

}
