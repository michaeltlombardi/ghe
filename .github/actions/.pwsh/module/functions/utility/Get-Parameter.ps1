function Get-Parameter {
    [CmdletBinding()]
    param(
        [pscustomobject[]]$ParameterHandler
    )

    begin {
        $ActionParameters = @{}
        $ErrorTarget = if ($env:GITHUB_ACTIONS) {
            $env:GITHUB_ACTION
        } else {
            $PSCmdlet.MyInvocation.InvocationName
        }

        function Update-ScriptBlockFromDataFile {
            [CmdletBinding()]
            param(
                [scriptblock]$ScriptBlock
            )

            begin {
                $Predicate = {
                    param([System.Management.Automation.Language.Ast]$AstObject)
                    return ($AstObject -is [System.Management.Automation.Language.ScriptBlockAst])
                }
            }

            process {
                $Stringified = $ScriptBlock.Ast.EndBlock.Extent.Text?.Trim()
                # Scriptblocks from data files get wrapped in extra curly braces, preventing them
                # from being invokable. Normally just the contents shows up when calling ToString()
                # on a scriptblock, so this is one way to tell.
                if ($Stringified -match '^\{') {
                    $NestedBlock = $ScriptBlock.Ast.FindAll($Predicate, $true)
                    | Where-Object -FilterScript { $_.EndBlock.Extent.Text.Trim() -notmatch '^\{' }
                    | Select-Object -First 1
                }

                if ($NestedBlock -is [System.Management.Automation.Language.ScriptBlockAst]) {
                    return $NestedBlock.GetScriptBlock()
                }

                return $ScriptBlock
            }

            end {}
        }
    }

    process {
        foreach ($Handler in $ParameterHandler) {
            $Value = Get-Item "Env:\INPUT_$($Handler.Name)" | Select-Object -ExpandProperty Value
            if ($Handler.Type -match 'String') {
                $NullHandler = Update-ScriptBlockFromDataFile -ScriptBlock $Handler.IfNullOrEmpty
                if ([string]::IsNullOrEmpty($Value) -and ($null -ne $NullHandler)) {
                    Set-Variable -Name InvocationParameters -Value @{
                        ScriptBlock  = $NullHandler
                        NoNewScope   = $true
                        ArgumentList = @(
                            $ErrorTarget
                        )
                    }
                    Invoke-Command @InvocationParameters
                }
            } else {
                $NullHandler = Update-ScriptBlockFromDataFile -ScriptBlock $Handler.IfNull
                if ($null -eq $Value -and ($null -ne $NullHandler)) {
                    Set-Variable -Name InvocationParameters -Value @{
                        ScriptBlock  = $NullHandler
                        NoNewScope   = $true
                        ArgumentList = @(
                            $ErrorTarget
                        )
                    }
                    Invoke-Command @InvocationParameters
                }
            }

            $ProcessScriptBlock = Update-ScriptBlockFromDataFile -ScriptBlock $Handler.Process
            if ($null -eq $ProcessScriptBlock) {
                throw 'no go bud, need a process script block'
            }

            Set-Variable -Name InvocationParameters -Value @{
                ScriptBlock  = $ProcessScriptBlock
                NoNewScope   = $true
                ArgumentList = @(
                    $ActionParameters
                    $Value
                    $ErrorTarget
                )
            }
            $ActionParameters = Invoke-Command @InvocationParameters
        }
    }

    end {
        $ActionParameters
    }
}