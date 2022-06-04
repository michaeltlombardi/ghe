@{
  Parameters = @(
    @{
      Name = 'Body'
      Type = 'string'
      IfNullOrEmpty = {
        param($ErrorTarget)

        $ErrorDetails = @{
          Name  = 'Body'
          Type  = 'Missing'
          Message = @(
            'Could not determine the body of the PR;'
            'was it passed as an input to the action?'
          ) -join ' '
          Target  = $ErrorTarget
        }
        $Record = New-InvalidParameterError @ErrorDetails

        throw $Record
      }
      Process = {
        param($Parameters, $Value, $ErrorTarget)

        $Parameters.Body = $Value
        Write-HostParameter -Name Body -Value $Parameters.Body -MultiLine

        return $Parameters
      }
    }

    @{
      Name          = 'Pull_Request_Url'
      Type          = 'string'
      IfNullOrEmpty = {
        param($ErrorTarget)

        $ErrorDetails = @{
          Name    = 'PullRequestUrl'
          Type    = 'Missing'
          Message = @(
            'Could not determine the URL of the PR;'
            'was it passed as an input to the action?'
          ) -join ' '
          Target  = $ErrorTarget
        }
        $Record = New-InvalidParameterError @ErrorDetails

        throw $Record
      }
      Process = {
        param($Parameters, $Value, $ErrorTarget)

        $Parameters.PullRequestUrl = $Value
        Write-HostParameter -Name PullRequestUrl -Value $Parameters.PullRequestUrl

        return $Parameters
      }
    }
  )
}