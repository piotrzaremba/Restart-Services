[System.Collections.ArrayList]$ServicesToRestart = @("Your Services Here") 
 
# Locate Dependencies
function Custom-GetDependServices ($ServiceInput) 
{ 
    #Write-Host "Name of `$ServiceInput: $($ServiceInput.Name)" 
    #Write-Host "Number of dependents: $($ServiceInput.DependentServices.Count)" 
    If ($ServiceInput.DependentServices.Count -gt 0) 
    { 
        ForEach ($DepService in $ServiceInput.DependentServices) 
        { 
            #Write-Host "Dependent of $($ServiceInput.Name): $($Service.Name)" 
            If ($DepService.Status -eq "Running") 
            { 
                #Write-Host "$($DepService.Name) is running." 
                $CurrentService = Get-Service -Name $DepService.Name 
                 
                # get dependancies of running service 
                Custom-GetDependServices $CurrentService                 
            } 
            Else 
            { 
                Write-Host "$($DepService.Name) is stopped. No Need to stop or start or check dependancies." 
            } 
             
        } 
    } 
    Write-Host "Service to restart $($ServiceInput.Name)" 
    if ($ServicesToRestart.Contains($ServiceInput.Name) -eq $false) 
    { 
        Write-Host "Adding service to restart $($ServiceInput.Name)" 
        $ServicesToRestart.Add($ServiceInput.Name) 
    } 
} 

# Email
function Email-Admin($body)
{
	$mail = New-Object System.Net.Mail.MailMessage
	$mail.From = “From@yourdomain.com”
	$mail.To.Add(“To@yourdomain.com”)
	$mail.Subject = $body
	$mail.Body = $body
	$smtp = New-Object System.Net.Mail.SmtpClient(“your.smtp.com”)
	$smtp.Send($mail)
}

# Logging
function Log($message)
{
    #  Log file time stamp:
    $logTime = Get-Date -Format "yyyy-MM-dd"

    #  Log file name:
    $path = "Your Path"

    if([IO.Directory]::Exists($path))
    {
        #Do Nothing!!
    }
    else
    {
        New-Item -ItemType directory -Path $path
    }

    $logFile = $path+$logTime+".log"
    
    "$message" | Out-File $logFile -Append -Force
}

Write-Host "-------------------------------------------" 
Write-Host "Check If All Services Are Running" 
Write-Host "-------------------------------------------"
$restartFlag = $False;
foreach($ServiceToCheck in $ServicesToRestart) 
{ 
    $service = Get-Service $ServiceToCheck -Verbose
    if($service.Status -ne "Running")
    {
        Email-Admin($ServiceToCheck + ” : not running. Restart is required.”)
        Write($ServiceToCheck + ” : not running. Restart is required.”)
        Log($ServiceToCheck + ” : not running. Restart is required.”)
        $restartFlag = $True
        break
    }
}

if($restartFlag -eq $False)
{
    Write-Host "-------------------------------------------" 
    Write("All services are running”);
    Write-Host "-------------------------------------------" 
    Email-Admin("All services are running”);
    exit
}

Write-Host "-------------------------------------------" 
Write-Host "Stopping Services" 
Write-Host "-------------------------------------------"

foreach($ServiceToStop in $ServicesToRestart) 
{ 
    Write-Host "Stop Service $ServiceToStop" 
    Stop-Service $ServiceToStop -Verbose #-Force 
}

Write-Host "-------------------------------------------" 
Write-Host "Starting Services" 
Write-Host "-------------------------------------------"
 
# Reverse stop order to get start order 
$ServicesToRestart.Reverse() 
 
foreach($ServiceToStart in $ServicesToRestart) 
{ 
    Write-Host "Start Service $ServiceToStart"
    # Get dependancies and stop order 
    Start-Service $ServiceToStart -Verbose
    $Service = get-service $ServiceToStart
    if($Service.Status -ne “Running”)
    {
         Email-Admin($ServiceToStart + ”: has failed to start, please manually start.”)
         Write($ServiceToStart+ ”: has failed to start, please manually start.”)
         Log($ServiceToStart+ ”: has failed to start, please manually start.”)
    }
    else
    {
         Email-Admin($ServiceToStart + ”: has started.”)
         Write($ServiceToStart+ ”: has started.”)
         Log($ServiceToStart+ ”: has started.”)
    }
}

Write-Host "-------------------------------------------" 
Write-Host "Restart of services completed" 
Write-Host "-------------------------------------------" 