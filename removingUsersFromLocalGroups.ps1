#A PS script that searches all the workstations and logs all the local group members. Later giving an option to 
#remove any user from local groups of their workstations. The script also logs the workstations that have no connectivity. 
#Author: Varunaditya Jadwal

#importing the active directory module
Import-Module ActiveDirectory
#adding all the domains in the array
#$startTime = $(get-date)
$domains = Get-content ".\domains.txt"
$outputFile = ".\machinesDetails.csv"
$failedConnectionsLogs = ".\failedConnections.txt"
$successfulConnectionsLogs = ".\successfulConnections.txt"
$groupDetailsFile = ".\membershipDetails" + $(date) + ".txt"
$localGroups = Get-content ".\groupsList.txt"
#removing the files if they already exists
if(Test-Path $outputFile) { remove-Item $outputFile }
if(Test-Path $failedConnectionsLogs) { remove-Item $failedConnectionsLogs }
if(Test-Path $successfulConnectionsLogs) { remove-Item $successfulConnectionsLogs }
if(Test-Path $groupDetailsFile) { remove-Item $groupDetailsFile }
#iterating through all the domains and appending the output in a csv file
foreach($domain in $domains){
	$outputStream += Get-ADComputer -fi "operatingSystem -like 'Windows *'" -prop * -Server $domain | 
	select -prop Name, DNSHostName, Enabled
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
$hostNames = Get-content $successfulConnectionsLogs #"C:\Users\vjadwal\Documents\successfulConnections.txt" 
$dataToBeWritten = @()
$membersToBeRemoved = @('Administrator', 'maintenance', 'Machine_setup', 'Domain Admins', 'ServerAdministrators', 'WorkstationAdministrators')
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
		$groupMembers = $groupMembers | select -unique
		$groupMembers = [System.Collections.ArrayList]$groupMembers
		#if($groupMembers.count -ne 0) {
			foreach($memberToBeRemoved in $membersToBeRemoved) { 
				if($groupMembers.count -ne 0) {
					$groupMembers.remove($memberToBeRemoved) 
				}
			}
		if($groupMembers.count -eq 0) { $groupMembers = 'Nothing unusual.'}
		else {$groupMembers = $groupMembers -join ', '}
		$dataToBeWritten += 'Members: ' + $groupMembers
	}
	$dataToBeWritten += '------------------------------------------------'
}
$dataToBeWritten > $groupDetailsFile
sleep(2)
notepad.exe $groupDetailsFile
#$elapsedTime = $(get-date) - $start
#write-host $elapsedTime.TotalMinutes
#removing users from a group
#$choice = 1
#while($choice){
#	$choice = read-host -prompt 'Remove A User From A Group? [1] Yes [2] No '
#	if($choice -eq 2) {break}
#	$hostName = read-host -prompt 'Host Name: '
#	$groupName = read-host -prompt 'Group Name: '
#	$memberName = read-host -prompt 'Member Name: '
#	invoke-command -computername $hostName -scriptBlock{remove-localgroupmember -Group $groupName -Member $memberName}
#	write-host "User Removed!!!"
#}