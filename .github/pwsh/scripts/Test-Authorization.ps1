<#
.SYNOPSIS
  Checks if a PR author is authorized to submit this PR.
.DESCRIPTION
  Checks if a PR author is authorized to submit this PR. An author is authorized if they have the
  **Maintain** or **Admin** permissions. If the author is not permitted to submit this PR, the
  script (and any GHA workflow calling it) fails.
.PARAMETER Owner
  The owner of the repository to check the author's permissions in. For `https://github.com/foo/bar`
  the owner is `foo`.
.PARAMETER Repo
  The name of the repository to check the author's permissions in. For `https://github.com/foo/bar`
  the repo is `bar`.
.PARAMETER Author
  The username to retrieve permissions for.
.PARAMETER TargetBranch
  Specifies the name of a branch requring maintainer permissions to target.
.PARAMETER TargetPath
  Specifies the path to one or more files requiring maintainer permissions to modify.
.EXAMPLE
  ./.github/pwsh/scripts/Test-Authorization.ps1 -Owner foo -Repo bar -Author baz -TargetBranch live

  The script checks the permissions of the `baz` user for https://github.com/foo/bar`. If `baz` has
  maintainer or admin permissions, the script exits without error. If they do not, the script throws
  an error declaring the `baz` does not have sufficient permissions to target the `live` branch.
.EXAMPLE
  ./.github/pwsh/scripts/Test-Authorization.ps1 -Owner foo -Repo bar -Author baz -TargetPath @(
    '.github/pwsh'
    '.github/workflows
  )

  The script checks the permissions of the `baz` user for https://github.com/foo/bar`. If `baz` has
  maintainer or admin permissions, the script exits without error. If they do not, the script throws
  an error declaring the `baz` does not have sufficient permissions to target either the `pwsh` or
  `workflows` folder.
.NOTES
  The **TargetBranch** and **TargetPath** parameters are for convenience; GitHub repositories do not
  have a built in way to define permissions for branches or folders except for branch protection,
  which is not sufficient for this purpose. To ensure this script is effective, use the **branches**
  and **paths** settings in the workflow when defining a **pull_request_target** job trigger.
#>
[cmdletbinding(DefaultParameterSetName='Branch')]
param(
  [Parameter(Mandatory)]
  [string]$Owner,
  [Parameter(Mandatory)]
  [string]$Repo,
  [Parameter(Mandatory)]
  [string]$Author,
  [Parameter(Mandatory, ParameterSetName='Branch')]
  [string]$TargetBranch,
  [Parameter(Mandatory, ParameterSetName='Path')]
  [string[]]$TargetPath
)

begin {
  <#
    Setup steps:

    - Need to import the GHA module, which contains all of the functions that interact with the API
      and includes helper utilities for console formatting.
    - Need a string builder to generate the markdown summary for this step.
    - Need to grab the values for ANSI and PlainText output rendering so the markdown in the summary
      doesn't include ANSI decorations.
    - Need to create empty arrays to grab the data on comments and failures.
    - Need to grab the path to the body file for the PR comment.
  #>
  $GitHubFolder = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
  $ModuleFile = Resolve-Path -Path "$GitHubFolder/pwsh/gha/gha.psm1"
  | Select-Object -ExpandProperty Path
  Import-Module $ModuleFile -Force
  $Summary = New-Object -TypeName System.Text.StringBuilder
  $Ansi = [System.Management.Automation.OutputRendering]::Ansi
  $Plain = [System.Management.Automation.OutputRendering]::PlainText
  $TargetStyle = @($PSStyle.Bold, $PSStyle.Foreground.BrightMagenta)
  $Texts = @{
    Success = @{
      Console = Format-ConsoleStyle -Text 'Success' -DefinedStyle Success
      Markdown = "**Success**"
    }
    Author = @{
      Console = Format-ConsoleStyle -Text $Author -DefinedStyle UserName
      Markdown = "``$Author``"
    }
  }
  if (![string]::IsNullOrEmpty($TargetBranch)) {
    $ConsoleBranch = Format-ConsoleStyle -Text $TargetBranch -StyleComponent $TargetStyle
    $Texts.Target = @{
      Console = "target the $ConsoleBranch branch."
      Markdown = "target the ``$TargetBranch`` branch."
      Error = "target the '$TargetBranch' branch."
    }
  } Else {
    $ConsolePaths = $TargetPath | Foreach-Object -Process {
      Format-ConsoleStyle -Text $_ -StyleComponent $TargetStyle
    }
    $MarkdownPaths = $TargetPath | ForEach-Object -Process {"- ``$_``"}
    $Texts.Target = @{
      Console = "modify file paths:`n`t$($ConsolePaths -join "`n`t")"
      Markdown = "modify file paths:`n`n$($MarkdownPaths -join "`n")"
      Error = "modify file paths:`n`t$($TargetPath -join "`n`t")"
    }
  }
}

process {
  try {
    $Permissions = Get-AuthorPermission -Owner $Owner -Repo $Repo -Author $Author
  } catch {
    $Record = $_ | Get-GHAConsoleError
    Write-ActionFailureSummary -Record $Record -Synopsis 'Unable to retrieve permissions.'
    $PSCmdlet.ThrowTerminatingError($_)
  }

  #region    Permission Retrieval Messaging
  # Markdown Summary
  $null = $Summary.AppendLine('## Retrieved Permissions').AppendLine()
  $null = $Summary.AppendLine("Retrieved permissions for for ``$Author``. Details:").AppendLine()
  $null = $Summary.AppendLine('```text')
  $PSStyle.OutputRendering = $Plain
  $PermissionsBlock = $Permissions | Format-List -Property * | Out-String
  $PSStyle.OutputRendering = $Ansi
  $null = $Summary.AppendLine($PermissionsBlock.Trim())
  $null = $Summary.AppendLine('```').AppendLine()
  # Console Logging
  "Retrieved permissions for $($Texts.Author.Console):"
  foreach ($Permission in @('Admin', 'Maintain', 'Pull', 'Push', 'Triage')) {
    $Prefix = "`t$($PSStyle.Bold)${Permission}:$($PSStyle.BoldOff)".PadRight(20)
    $Setting = Format-ConsoleBoolean -Value $Permissions.$Permission
    "$Prefix`t$Setting"
  }
  #endregion Permission Retrieval Messaging
  
  $null = $Summary.AppendLine('## Result').AppendLine()
  $Authorized  = $Permissions.Admin -or $Permissions.Maintain
  if ($Authorized) {
    # Markdown Summary
    $null = $Summary.AppendLine(
      "**Success:** Author (``$Author``) may $($Texts.Target.Markdown)"
    )
    $Summary.ToString() >> $ENV:GITHUB_STEP_SUMMARY
    # Console Logging
    $ConsoleMessage = New-Object -TypeName System.Text.StringBuilder
    $null = $ConsoleMessage.Append("$($Texts.Success.Console): ")
    $null = $ConsoleMessage.Append("author ($($Texts.Author.Console)) ")
    $null = $ConsoleMessage.Append("may $($Texts.Target.Console)")
    $ConsoleMessage.ToString()
  } else {
    # Markdown Summary
    $null = $Summary.AppendLine(
      "**Failure:** Author (``$Author``) may not $($Texts.Target.Markdown)"
    )
    $Summary.ToString() >> $ENV:GITHUB_STEP_SUMMARY
    # Console Logging / Throw Error
    $Message = "Author ($($Texts.Author.Console)) may not $($Texts.Target.Error)"
    $Message = Format-GHAConsoleText -Text $Message
    $Exception = [System.ApplicationException]::new($Message)
    $TargetObject = $TargetBranch || $TargetPath
    $Record = [System.Management.Automation.ErrorRecord]::new(
        $Exception,
        'GHA.NotPermittedToTarget',
        [System.Management.Automation.ErrorCategory]::PermissionDenied,
        $TargetObject
    )
    $PSCmdlet.ThrowTerminatingError($Record)
  }
}

end {}