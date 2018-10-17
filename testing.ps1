$hostNames = Get-content "C:\Users\vjadwal\Documents\hostNames.txt" 
$localGroups = 'Administrators'
$groupDetailsFile = "C:\Users\vjadwal\Documents\finalOutpiut.txt"
$dataToBeWritten = @()
$membersToBeremoved = @('Administrator', 'maintenance', 'Machine_setup', 'Domain Admins', 'ServerAdministrators', 'WorkstationAdministrators')

foreach ($hostName in $hostNames){
	$dataToBeWritten += 'Hostname: ' + $hostName
	foreach ($localGroup in $localGroups){
		$dataToBeWritten += 'Local Group: ' + $localGroup
		$groupMembers = Invoke-Command -Computer $hostName -ScriptBlock {
			$group = [ADSI]("WinNT://$env:COMPUTERNAME/$($args[0]),group")
			$group.PSBase.Invoke('Members') | % {
			$_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
			}
		} -ArgumentList $localGroup -EA SilentlyContinue
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
		#$dataToBeWritten += ''
	}
	$dataToBeWritten += '------------------------------------------------'
}
$dataToBeWritten > $groupDetailsFile
sleep(1)
notepad.exe $groupDetailsFile
$choice = 1
while($choice){
$choice = read-host -prompt 'Remove A User From A Group? [1] Yes [2] No '
	if($choice -eq 2) {break}
	$hostName = read-host -prompt 'Host Name: '
	$groupName = read-host -prompt 'Group Name: '
	$memberName = read-host -prompt 'Member Name: '
	invoke-command -computername $hostName -scriptBlock{remove-localgroupmember -Group $groupName -Member $memberName}
	write-host "User Removed!!!"
}