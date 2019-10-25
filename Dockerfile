# escape=`

#--haal basis container op (kale windows server core voorzien van IIS)
   FROM microsoft/iis

# installeer dotNet
#   SHELL ["powershell"]
   RUN powershell Install-WindowsFeature NET-Framework-45-ASPNET; Install-WindowsFeature Web-Asp-Net45

# diverse windows instellingen bijwerken
   #-- standaard shell    
   ENTRYPOINT powershell 
   #-- Docker DNS gebruiken door caching te disablen
   RUN powershell set-itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord  

# verwijder de standaard website
   RUN powershell Stop-Website -Name 'Default Web Site'
   RUN powershell Remove-Website -Name 'Default Web Site'

# Variabelen en labels
ARG omgeving=TEST
ARG poort=8080
ENV omgeving=${omgeving}
ENV poort=${poort}
LABEL com.SpoorWeb.omgeving="docker" `
      maintainer="arno.koster@prorail.nl" `
      omgeving=$omgeving `
      poort=$website_port

# variabelen beschikbaar maken tijdens run-time
#   foreach($key in [System.Environment]::GetEnvironmentVariables('Process').Keys) {`
#       if ([System.Environment]::GetEnvironmentVariable($key, 'Machine') -eq $null) {`
#           $value = [System.Environment]::GetEnvironmentVariable($key, 'Process')`
#           [System.Environment]::SetEnvironmentVariable($key, $value, 'Machine')`
#       }`
#   }

# IIS configureren om variabelen uit te kunnen lezen
   RUN powershell Start-Process -NoNewWindow -FilePath C:\ServiceMonitor.exe -ArgumentList w3svc;

# IIS configureren om logbestanden weg te schrijven
   RUN netsh http flush logbuffer `
       powershell Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; `
       powershell Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295; `
       powershell Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'; `
       powershell Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v 'c:\inetpub\logs'

#regel Healthcheck
   HEALTHCHECK --interval=5s `
      CMD powershell -command `
         try { `
            $response = iwr http://localhost:$poort -UseBasicParsing; `
            if ($response.StatusCode -eq 200) { return 0} `
            else {return 1}; `
         } catch { return 1 }

# maak de nieuwe website aan
   #RUN echo website aanmaken op poort %poort% 
   RUN powershell New-Website -Name 'test-website' -Port %poort% -PhysicalPath 'c:\inetpub\wwwroot'    
   EXPOSE $poort

# vul de website met informatie
   COPY inetpub c:\\inetpub
   RUN echo omgeving: %omgeving% >> c:\\inetpub\\wwwroot\\index.html `
       echo poort: %poort% >> c:\\inetpub\\wwwroot\\index.html

#-- CMD mogelijkheden:
#    Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null; `
#    Get-Content -path 'C:\iislog\W3SVC\u_extend1.log' -Tail 1 -Wait 
