write-host @"  



███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗     ██████╗ ██████╗  █████╗ ██████╗ ██████╗ ███████╗██████╗ 
██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║    ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║    ██║  ███╗██████╔╝███████║██████╔╝██████╔╝█████╗  ██████╔╝
╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║    ██║   ██║██╔══██╗██╔══██║██╔══██╗██╔══██╗██╔══╝  ██╔══██╗
███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║    ╚██████╔╝██║  ██║██║  ██║██████╔╝██████╔╝███████╗██║  ██║
╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                                               

           Written By: Anthony Tippy                                                                                                        

"@

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#Credentials
$username = 'USERNAME'
$password = 'PASSWORD'

#Import PSCRESTRON MODULE
Import-Module PSCrestron

$local = 

#Delete old Screenshot Folder
Remove-Item ".\Desktop\Screenshots" -Recurse -ErrorAction SilentlyContinue

#Create Screenshot folder
New-Item -Path ".\Desktop" -Name "Screenshots" -ItemType "directory" -ErrorAction SilentlyContinue

# import device file
try
	{
    $devs = (Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	Write-Host ' '
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device IP.txt is in same directory as script!!!'
	}

#Version
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
    try {
        $d = $_
        $DeviceResultItem = New-Object PSObject

        #New Crestron Session
        $session = Open-CrestronSession -Device $d -secure
        #Read-Host -Prompt “Crestron Session Connected Press Enter to exit`n"

        #Hostname Extraction
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

        Write-Host -f Green "`n`n`n[Default Password]  Grabbing Screenshot for:" $d "==>" $deviceHostname

        #Screenshot command
        $screenshot= Invoke-CrestronSession $session "screenshot $deviceHostname"

        $Remotefile = ('logs\' + $deviceHostname + '.bmp')

        Get-FTPFile -Device $d -RemoteFile $Remotefile -localPath .\Desktop\Screenshots -port 22 -erroraction Continue 

        #Cleanup -Remove Screenshot from device
        $cleanup = Remove-FTPFile -device $d -RemoteFile $Remotefile -secure -port 22 -erroraction Continue

        #Close Crestron Session
        Close-CrestronSession $session
        } 

    catch {"$_ Couldn't connect"
        try {

        $DeviceResultItem = New-Object PSObject

        #New Crestron Session
        $session = Open-CrestronSession -Device $d -secure #-Username $username -Password $password

        #Hostname Extraction
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

        Write-Host -f Green "`n`n`n[Custom Password]  Grabbing Screenshot for:" $d "==>" $deviceHostname

        #Screenshot command
        $screenshot= Invoke-CrestronSession $session "screenshot $deviceHostname"

        $Remotefile = ('logs\' + $deviceHostname + '.bmp')

        Get-FTPFile -Device $d -RemoteFile $Remotefile -localPath .\Desktop\Screenshots -secure 

        #Cleanup -Remove Screenshot from device
        $cleanup = Remove-FTPFile -device $d -RemoteFile $Remotefile -secure 

        #Close Crestron Session
        Close-CrestronSession $session
        } 

        Catch {
            Write-Host -f Red "`n`n`nError Connecting to " $d
            write-host " "

            Continue 
               }
    }

} -ShowProgress #-TIMEOUT 1

#Total time of script
$stopwatch


Read-Host -Prompt “Press Enter to exit”
