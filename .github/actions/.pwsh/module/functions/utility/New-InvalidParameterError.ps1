function New-InvalidParameterError {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,
        [parameter(Mandatory)]
        [string]$Message,
        [parameter(Mandatory)]
        [string]$Target,
        [ValidateSet('Missing', 'Invalid')]
        [string]$Type = 'Missing'
    )

    begin {}

    process {
        $Message   = Format-GHAConsoleText -Text $Message
        switch ($Type) {
            'Missing' {
                $Exception = [System.Management.Automation.PSArgumentNullException]::new(
                    $Name,
                    $Message
                )
                $ErrorID =  'GHA.MissingParameter'
            }
            default { # Includes 'Invalid'
                $Exception = [System.Management.Automation.PSArgumentException]::new(
                    $Message,
                    $Name
                )
                $ErrorID =  'GHA.InvalidParameter'
            }
        }
        $Target    = Format-GHAConsoleText -Text $Target
        [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            $ErrorID,
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $TargetObject
        )
    }

    end {}
}