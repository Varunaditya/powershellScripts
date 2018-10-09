#A PS script that searches all the workstations and logs all the local group members. Later giving an option to 
#remove any user from local groups of their workstations. The script also logs the workstations that have no connectivity. 
#Author: Varunaditya Jadwal

#importing the active directory module
Import-Module ActiveDirectory
#adding all the domains in the array
$domains = Get-content "C:\Users\vjadwal\Documents\domains.txt"
$outputFile = "C:\Users\vjadwal\Documents\machinesDetails.csv"
$failedConnectionsLogs = "C:\Users\vjadwal\Documents\failedConnections.txt"
$successfulConnectionsLogs = "C:\Users\vjadwal\Documents\successfulConnections.txt"
$groupDetailsFile = "C:\Users\vjadwal\Documents\membershipDetails.txt"
#removing the files if they already exists
if(Test-Path $outputFile) { remove-Item $outputFile }
if(Test-Path $failedConnectionsLogs) { remove-Item $failedConnectionsLogs }
if(Test-Path $successfulConnectionsLogs) { remove-Item $successfulConnectionsLogs }
#iterating through all the domains and appending the output in a csv file
foreach($domain in $domains){
	$outputStream += Get-ADComputer -fi "operatingSystem -like 'Windows *'" -prop * -Server $domain | 
	select -prop Name, DNSHostName, Enabled, LastLogonDate
}
#eliminating any redundancy in 'Names'. This happens due to one machine being part of more than one domain
$outputStream | Sort-Object 'Name' -Unique | Export-Csv $outputFile
#declaring an array
$successfulConnections = @()
$failedConnections = @()
#importing the CSV file and reading it line-by-line
Import-Csv $outputFile | ForEach-Object {
	#run test-connection only on machines that has the 'ENABLED' field set to TRUE in the CSV
	if($_.Enabled -eq 'TRUE'){
		$connectivity = Test-Connection $_.Name -Quiet -Count 1
		#adds the host name to the array if it cannot be reached 
		if(!$connectivity){
			$failedConnections += $_.Name
		}
		else{
			$successfulConnections += $_.Name
		}
	}
	#the entries with 'ENABLED' set to FALSE are always added to the array
	else{
		$failedConnections += $_.Name
	}
}
#the values of the array are written to a file
$failedConnections > $failedConnectionsLogs
$successfulConnections > $successfulConnectionsLogs
#finding local members
$hostNames = Get-content "C:\Users\vjadwal\Documents\successfulConnections.txt"
$localGroups = Get-content "C:\Users\vjadwal\Documents\groupsList.txt"
$outputFile = "C:\Users\vjadwal\Documents\groupMembers.txt"
$dataToBeWritten = @()
foreach ($hostName in $hostNames){
	$dataToBeWritten += 'Hostname: ' + $hostName
	foreach ($localGroup in $localGroups){
		$dataToBeWritten += 'Local Group: ' + $localGroups
		$groupMembers = Invoke-Command -Computer $hostName -ScriptBlock {
			$group = [ADSI]("WinNT://$env:COMPUTERNAME/$($args[0]),group")
			$group.PSBase.Invoke('Members') | % {
			$_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
			}
		} -ArgumentList $localGroups -EA SilentlyContinue
		$dataToBeWritten += 'Members: ' + $groupMembers
		$dataToBeWritten += ''
	}
	$dataToBeWritten += '------------------------------------------------'
}
$dataToBeWritten > $groupDetailsFile
notepad.exe $groupDetailsFile
#removing users from a group
#$choice = read-host -prompt 'Remove A User From A Group? [1] Yes [2] No '
#while(choice){
#	if($choice -eq 2) {break}
#	$hostName = read-host -prompt 'Host Name: '
#	$groupName = read-host -prompt 'Group Name: '
#	$memberName = read-host -prompt 'Member Name: '
#	invoke-command -computername $hostName -scriptBlock{remove-localgroupmember -Group $groupName -Member $memberName}
#}