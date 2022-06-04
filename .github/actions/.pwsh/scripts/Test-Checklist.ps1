[CmdletBinding()]
param(
    [string]$Body,
    [string]$PullRequestUrl
)

begin {
    $GitHubFolder = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
    $ModuleFile = Resolve-Path -Path "$GitHubFolder/.pwsh/module/gha.psd1"
    | Select-Object -ExpandProperty Path
    Import-Module $ModuleFile -Force
    # Style Setup
    $NameStyle = $PSStyle.Foreground.BrightYellow
    $StatusStyle = @{
        Symbol = @{
            Checked = '✔ '
            Missing = '✖ '
        }
        Font = @{
            Checked = $PSStyle.Bold + $PSStyle.Foreground.BrightBlue
            Missing = $PSStyle.Bold + $PSStyle.Foreground.BrightMagenta
        }
    }
    $Summary = New-Object -TypeName System.Text.StringBuilder
    # Initialize variables
    $MissingItemCount = 0
}

process {
    # Get Checklist Items
    $null = $Summary.AppendLine('# Pull Request Checklist').AppendLine()
    $null = $Summary.AppendLine('| Item | State |')
    $null = $Summary.AppendLine('|:-----|:-----:|')
    $CheckListItems = $Body -split "`n" | ForEach-Object {
        if ($_ -match '- \[(?<Checked>.)\] \*\*(?<Name>.+):') {
            $Status = $Matches.Checked -eq 'x' ? 'Checked' : 'Missing'
            $Font = $StatusStyle.Font.$Status
            $Name = $Matches.Name
            [PSCustomObject]@{
                Name = $NameStyle + $Name + $PSStyle.Reset
                Prefix = $Font + $StatusStyle.Symbol.$Status + $PSStyle.Reset
                Status = $Font + $Status + $PSStyle.Reset
            }
            $null = $Summary.AppendLine("| **$Name** | $($StatusStyle.Symbol.$Status) |")
        }
    }

    # Add final newline and write summary; at this point we know everything we need for
    # the summary itself, the rest is for console logging and failure reporting
    $null = $Summary.AppendLine()
    $Summary.ToString() >> $ENV:GITHUB_STEP_SUMMARY
    
    # Get an appropriate padding width so the status values line up
    $PaddingWidth = 0
    $CheckListItems | ForEach-Object -Process {
        $Width = ($_.Prefix + "`t" + $_.Name).Length + 3 # pad right for the colon and space
        if ($PaddingWidth -lt $Width) {
            $PaddingWidth = $Width
        }
    }
    
    
    # Display Results
    foreach ($Item in $CheckListItems) {
        if ($Item.Prefix -notmatch '✔') {
            $MissingItemCount++
        }
        
        "$($Item.Prefix)$($Item.Name): ".PadRight($PaddingWidth) + $Item.Status
    }
    
    # Write summary message + exit if any checks are missing
    if ($MissingItemCount) {
        "" # Add a blank line before message
        $Message = @(
            "Missing $MissingItemCount of the checklist items."
            'Please review the PR checklist.'
        ) -join ' '
        $Message = Format-GHAConsoleText -Text $Message
        $Exception = [System.ApplicationException]::new($Message)
        $Record = [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            'GHA.Checklist.NotComplete',
            [System.Management.Automation.ErrorCategory]::InvalidResult,
            $PullRequestUrl
        )
        $PSCmdlet.ThrowTerminatingError($Record)
    }
}

end {}