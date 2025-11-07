Get-WinEvent -ComputerName $env:ComputerName -FilterHashtable @{logname = 'System'; id = 1074,6008}  |
ForEach-Object {
$EventData = New-Object PSObject | Select-Object Date, EventID, User, Action, Reason, ReasonCode, Comment, Computer, Message, Process
$EventData.Date = $_.TimeCreated
$EventData.User = $_.Properties[6].Value
$EventData.Process = $_.Properties[0].Value
$EventData.Action = $_.Properties[4].Value
$EventData.Reason = $_.Properties[2].Value
$EventData.ReasonCode = $_.Properties[3].Value
$EventData.Comment = $_.Properties[5].Value
$EventData.Computer = $env:ComputerName
$EventData.EventID = $_.id
$EventData.Message = $_.Message
                    
$EventData | Select-Object Date, Computer, EventID, Action, User, Reason, Message
} | select -first 20

cmd /c 'pause'