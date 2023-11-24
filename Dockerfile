# Use the Windows Server Core image with IIS
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019

# Set environment variables
ENV site_name "MyWebsite"
ENV app_pool_name "MyAppPool"

# Create a custom application pool
RUN powershell -NoProfile -Command \
    Import-Module WebAdministration; \
    New-WebAppPool -Name $env:app_pool_name; \
    Set-ItemProperty IIS:\\AppPools\\$env:app_pool_name -Name managedRuntimeVersion -Value ''

# Copy the website files to the container
COPY path/to/your/website/files C:/inetpub/wwwroot

# Configure SSL certificate
# This step depends on how you manage your SSL certificates.
# You might need to import a certificate and bind it to your website.
# Example (replace with your actual certificate details):
COPY path/to/your/certificate.pfx C:/
RUN powershell -NoProfile -Command \
    $pwd = ConvertTo-SecureString -String 'your_certificate_password' -Force -AsPlainText; \
    Import-PfxCertificate -FilePath C:/certificate.pfx -CertStoreLocation cert:\\localMachine\\My -Password $pwd; \
    New-WebBinding -Name $env:site_name -Protocol https -Port 443 -SslFlags 0; \
    $cert = Get-ChildItem -Path cert:\\localMachine\\My | Where-Object { $_.Subject -match 'your_certificate_subject' }; \
    $binding = Get-WebBinding -Name $env:site_name -Protocol https; \
    $binding.AddSslCertificate($cert.GetCertHashString(), 'my')

# Assign the website to the custom application pool
RUN powershell -NoProfile -Command \
    Set-ItemProperty IIS:\\Sites\\$env:site_name -Name applicationPool -Value $env:app_pool_name

# Expose the port for the website
EXPOSE 80
EXPOSE 443

