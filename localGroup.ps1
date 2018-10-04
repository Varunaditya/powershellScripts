#A PS script that reads the host names and group names from a text file and lists 
#all the members on that host name from those groups 
#Author: Varunaditya Jadwal

$hostNames = Get-content "C:\Users\vjadwal\Documents\successfulConnections.txt"
$localGroups = Get-content "C:\Users\vjadwal\Documents\groupsList.txt"
$outputFile = "C:\Users\vjadwal\Documents\groupMembers.txt"
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
	$dataToBeWritten += '------------------------------------------------'
}
$dataToBeWritten > $outputFile