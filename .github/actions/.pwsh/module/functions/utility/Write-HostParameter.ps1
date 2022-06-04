function Write-HostParameter {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string[]]$Value,
        [switch]$MultiLine,
        [string]$Color = $PSStyle.Foreground.BrightMagenta
        
    )

    begin {}

    process {
        $Prefix = "${Name}: ".PadLeft(20)
        if ($MultiLine) {
            $MultilineValue = $Value -split "`n"
            | ForEach-Object -Process { "$(' ' * 20)$_" }
            | Join-String -Separator "`n"
            Write-Verbose "Body:`n$MultiLineValue"
            $MultilineValue = $PSStyle.Bold + $Color + $MultilineValue + $PSStyle.Reset
            Write-Verbose "After formatting:`n$MultilineValue"
            $Message = "$Prefix`n$MultilineValue"
        } else {
            $Values = $Value
            | ForEach-Object -Process { $PSStyle.Bold + $Color + $_ + $PSStyle.Reset }
            | Join-String -Separator ', '
            $Message = $Prefix + $Values
        }

        Write-Host $Message
    }

    end {}
}