#	Kollar, Edward ekollar@ford.com	
#	2016/12/08

	$objShell = New-Object -ComObject Shell.Application 
    $objFolder = $objShell.Namespace(0xA)
    $temp = get-ChildItem "env:\TEMP" 
    $temp2 = $temp.Value 
    $swtools = "c:\SWTOOLS\*" 
    $WinTemp = "c:\Windows\Temp\*"
 
#1# Remove temp files located in "C:\Users\USERNAME\AppData\Local\Temp" 
    write-Host "Removing Junk files in $temp2." -ForegroundColor Magenta  
    Remove-Item -Recurse  "$temp2\*" -Force -Verbose 
	
#2# Empty Recycle Bin
    write-Host "Emptying Recycle Bin." -ForegroundColor Cyan  
    $objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false} 
     
#3# Remove Windows Temp Directory  
    write-Host "Removing Junk files in $WinTemp." -ForegroundColor Green 
    Remove-Item -Recurse $WinTemp -Force  
     
#4# Running Disk Clean up Tool  
    #write-Host "Finally now , Running Windows disk Clean up Tool" -ForegroundColor Cyan 
    #cleanmgr /sagerun:1 | out-Null  
     
    $([char]7) 
    Sleep 1  
    $([char]7) 
    Sleep 1
     
    write-Host "Finished the cleanup task!" -ForegroundColor Yellow
	Sleep 5