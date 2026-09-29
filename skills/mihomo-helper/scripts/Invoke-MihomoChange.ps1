#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Apply', 'Commit', 'Rollback', 'Watchdog')][string]$Mode = 'Apply',
    [string]$PlanPath,
    [string]$TransactionPath,
    [switch]$ValidationPassed
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:EntryPath = $PSCommandPath

function Get-MhHash([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { return 'ABSENT' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Get-MhTextHash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '') }
    finally { $sha.Dispose() }
}
function Get-MhPath([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:\\' -or $Path -match '["\r\n]' -or $Path.Substring(2).Contains(':')) {
        throw 'Use an absolute local drive path without quotes, newlines or alternate streams.'
    }
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.Length -gt 3) { $full = $full.TrimEnd('\') }
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse points are not supported: $cursor"
            }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}
function Assert-MhProtected([string]$Path) {
    $null = Get-MhPath $Path
    $acl = Get-Acl -LiteralPath $Path
    $allowed = @($script:OwnerSid, 'S-1-5-18', 'S-1-5-32-544')
    if ($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -notin $allowed) { throw "Untrusted owner: $Path" }
    $writes = [Security.AccessControl.FileSystemRights]'Write,Delete,DeleteSubdirectoriesAndFiles,ChangePermissions,TakeOwnership'
    foreach ($rule in $acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
        if ($rule.AccessControlType -eq 'Allow' -and ($rule.FileSystemRights -band $writes) -and $rule.IdentityReference.Value -notin $allowed) {
            throw "Other accounts can modify: $Path"
        }
    }
}
function New-MhPrivateDirectory([string]$Path) {
    $null = Get-MhPath $Path
    if (!(Test-Path -LiteralPath $Path)) {
        $acl = New-Object Security.AccessControl.DirectorySecurity
        $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier($script:OwnerSid)))
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($sid in @($script:OwnerSid, 'S-1-5-18', 'S-1-5-32-544')) {
            $rule = New-Object Security.AccessControl.FileSystemAccessRule(
                (New-Object Security.Principal.SecurityIdentifier($sid)), 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
        }
        $null = [IO.Directory]::CreateDirectory($Path, $acl)
    }
    Assert-MhProtected $Path
}
function Save-MhState($State, [string]$Directory) {
    $target = Join-Path $Directory 'state.json'
    $temp = Join-Path $Directory ('state-' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllText($temp, ($State | ConvertTo-Json -Depth 12), (New-Object Text.UTF8Encoding($false)))
    # PowerShell 5.1 converts $null to an empty string for .NET string parameters.
    if (Test-Path -LiteralPath $target) { [IO.File]::Replace($temp, $target, [System.Management.Automation.Language.NullString]::Value) }
    else { [IO.File]::Move($temp, $target) }
}
function Read-MhState([string]$Directory) {
    Assert-MhProtected $Directory
    $state = Get-Content -LiteralPath (Join-Path $Directory 'state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($state.OwnerSid -ne $script:OwnerSid) { throw 'Use the original interactive account for this transaction.' }
    return $state
}
function Get-MhArguments($Plan) { return '-d "{0}" -f "{1}"' -f $Plan.DataDirectory, $Plan.ConfigPath }
function Get-MhInstance($Plan) {
    $sameName = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -ieq [IO.Path]::GetFileName($Plan.BinaryPath) })
    if (@($sameName | Where-Object { !$_.ExecutablePath }).Count) { throw 'Cannot identify a same-name process; refusing to guess.' }
    $found = @($sameName | Where-Object { $_.ExecutablePath -ieq $Plan.BinaryPath })
    if ($found.Count -gt 1) { throw 'Multiple instances share this binary; use a dedicated binary before maintenance.' }
    if ($found.Count) {
        $exe = [regex]::Escape($Plan.BinaryPath)
        $pattern = '^(?:"' + $exe + '"|' + $exe + ')\s+' + [regex]::Escape((Get-MhArguments $Plan)) + '\s*$'
        if ($found[0].CommandLine -notmatch $pattern) { throw 'The running instance does not have the exact reviewed -d/-f invocation.' }
        return $found[0]
    }
    return $null
}
function Get-MhInstanceKey($Instance) {
    if (!$Instance) { return '' }
    return '{0}:{1}' -f $Instance.ProcessId, $Instance.CreationDate.ToUniversalTime().ToString('o')
}
function Get-MhTaskFingerprint([string]$XmlText) {
    [xml]$xml = $XmlText
    $node = $xml.SelectSingleNode('/*[local-name()="Task"]/*[local-name()="Settings"]/*[local-name()="Enabled"]')
    if (!$node) { throw 'Task XML has no task-level Enabled setting.' }
    $node.InnerText = 'true'
    return Get-MhTextHash $xml.OuterXml
}
function Get-MhTask($Plan) {
    if (!$Plan.TaskName) { return $null }
    $task = Get-ScheduledTask -TaskName $Plan.TaskName -TaskPath $Plan.TaskPath
    if (@($task).Count -ne 1 -or @($task.Actions).Count -ne 1) { throw 'Expected one task with one direct executable action.' }
    $action = $task.Actions[0]
    if ($action.Execute -ine $Plan.BinaryPath -or $action.Arguments -cne (Get-MhArguments $Plan) -or $action.WorkingDirectory -ine $Plan.DataDirectory) {
        throw 'Task path, working directory or arguments differ from the reviewed invocation; shell wrappers are unsupported.'
    }
    $userId = [string]$task.Principal.UserId
    if ($userId -notmatch '^S-1-') { $userId = (New-Object Security.Principal.NTAccount($userId)).Translate([Security.Principal.SecurityIdentifier]).Value }
    if ($userId -ne $script:OwnerSid -or [string]$task.Principal.LogonType -ne 'Interactive' -or [string]$task.Principal.RunLevel -ne 'Highest') { throw 'Only the same interactive user task is supported, not SYSTEM or another account.' }
    $xml = Export-ScheduledTask -TaskName $Plan.TaskName -TaskPath $Plan.TaskPath
    return [pscustomobject]@{ Enabled = [bool]$task.Settings.Enabled; Running = ([string]$task.State -eq 'Running'); Fingerprint = (Get-MhTaskFingerprint $xml); Xml = $xml }
}
function Assert-MhTaskUnchanged($State) {
    $now = Get-MhTask $State.Plan
    if ($State.Task -and $now.Fingerprint -ne $State.Task.Fingerprint) { throw 'Task definition changed concurrently; refusing to overwrite it.' }
}
function Stop-MhInstance($State) {
    Assert-MhTaskUnchanged $State
    if ($State.Task) {
        Disable-ScheduledTask -TaskName $State.Plan.TaskName -TaskPath $State.Plan.TaskPath | Out-Null
        if ((Get-MhTask $State.Plan).Running) { Stop-ScheduledTask -TaskName $State.Plan.TaskName -TaskPath $State.Plan.TaskPath }
    }
    $instance = Get-MhInstance $State.Plan
    if ($instance) {
        $process = Get-Process -Id $instance.ProcessId
        try {
            $null = $process.Handle
            if ([Math]::Abs(($process.StartTime.ToUniversalTime() - $instance.CreationDate.ToUniversalTime()).TotalMilliseconds) -gt 1) { throw 'Process identity changed.' }
            $process.Kill()
            if (!$process.WaitForExit(10000)) { throw 'Owned process did not exit.' }
        } finally { $process.Dispose() }
    }
}
function Resume-MhInstance($State, [bool]$Start) {
    Assert-MhTaskUnchanged $State
    if ($State.Task) {
        if ($State.Task.Enabled) { Enable-ScheduledTask -TaskName $State.Plan.TaskName -TaskPath $State.Plan.TaskPath | Out-Null }
        else { Disable-ScheduledTask -TaskName $State.Plan.TaskName -TaskPath $State.Plan.TaskPath | Out-Null }
    }
    if (!$Start) { return }
    if ($State.Task -and $State.Task.Enabled -and $State.Task.Running) {
        Start-ScheduledTask -TaskName $State.Plan.TaskName -TaskPath $State.Plan.TaskPath
    } else {
        Start-Process -FilePath $State.Plan.BinaryPath -ArgumentList (Get-MhArguments $State.Plan) -WorkingDirectory $State.Plan.DataDirectory -WindowStyle Hidden | Out-Null
    }
    $limit = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 200
        $instance = Get-MhInstance $State.Plan
        if ($instance) {
            Start-Sleep -Seconds 1
            if ((Get-MhInstanceKey (Get-MhInstance $State.Plan)) -eq (Get-MhInstanceKey $instance)) { return }
        }
    } while ([DateTime]::UtcNow -lt $limit)
    throw 'Candidate did not stay running. This is only a process check, not a routing check.'
}
function Set-MhFile([string]$Source, [string]$Target) {
    $temp = Join-Path ([IO.Path]::GetDirectoryName($Target)) ('.mihomo-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::Copy($Source, $temp, $false)
        if (Test-Path -LiteralPath $Target) { [IO.File]::Replace($temp, $Target, [System.Management.Automation.Language.NullString]::Value) }
        else { [IO.File]::Move($temp, $Target) }
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}
function Remove-MhWatchdog($State) {
    $task = Get-ScheduledTask -TaskName $State.Watchdog -TaskPath '\' -ErrorAction SilentlyContinue
    if ($task) { Unregister-ScheduledTask -TaskName $State.Watchdog -TaskPath '\' -Confirm:$false }
}
function Restore-MhTransaction($State, [string]$Directory) {
    if ($State.Phase -in @('Committed', 'RolledBack')) { return }
    try {
        Assert-MhTaskUnchanged $State
        if ($State.Task -and $State.Phase -eq 'PendingValidation' -and (Get-MhTask $State.Plan).Enabled -ne $State.Task.Enabled) { throw 'Task enabled state changed after Apply.' }
        foreach ($file in $State.Files) {
            if ($State.Mutating -and (Get-MhHash $file.Target) -notin @($file.Before, $file.After)) { throw "Concurrent file edit: $($file.Target)" }
            if ($file.Touched -and $file.Before -ne 'ABSENT' -and (Get-MhHash $file.Backup) -ne $file.Before) { throw 'Backup integrity check failed.' }
        }
        if ($State.Mutating) {
            $State.Phase = 'RollingBack'; Save-MhState $State $Directory
            Stop-MhInstance $State
            foreach ($file in $State.Files) {
                if (!$file.Touched) { continue }
                if ($file.Before -eq 'ABSENT') { if (Test-Path -LiteralPath $file.Target) { Remove-Item -LiteralPath $file.Target -Force } }
                else { Set-MhFile $file.Backup $file.Target }
            }
            Resume-MhInstance $State $State.WasRunning
        }
        $State.Phase = 'RolledBack'; Save-MhState $State $Directory
        Remove-MhWatchdog $State
    } catch {
        $State.Phase = 'RecoveryFailed'; Save-MhState $State $Directory
        throw "Recovery failed; retain protected snapshots at $Directory. $($_.Exception.Message)"
    }
}
function Assert-MhPlan($Plan) {
    $fields = @('BinaryPath','ConfigPath','DataDirectory','ExpectedBinarySha256','ExpectedConfigSha256','CandidateBinaryPath','CandidateBinarySha256','CandidateConfigPath','CandidateConfigSha256','TaskName','TaskPath','StartAfterChange','RollbackAfterSeconds')
    foreach ($field in $fields) { if ($field -notin $Plan.PSObject.Properties.Name) { throw "Missing plan field: $field" } }
    if (@($Plan.PSObject.Properties.Name | Where-Object { $_ -notin $fields }).Count) { throw 'Unknown plan fields.' }
    if ($Plan.StartAfterChange -isnot [bool] -or ($Plan.RollbackAfterSeconds -isnot [long] -and $Plan.RollbackAfterSeconds -isnot [int])) { throw 'Use a JSON boolean and integer for start/timeout.' }
    if ($Plan.RollbackAfterSeconds -lt 15 -or $Plan.RollbackAfterSeconds -gt 1800) { throw 'RollbackAfterSeconds must be 15..1800 (normally 300).' }
    if (!$Plan.CandidateBinaryPath -and !$Plan.CandidateConfigPath) { throw 'No candidate change requested.' }
    foreach ($name in @('BinaryPath','ConfigPath','DataDirectory')) { $Plan.$name = Get-MhPath $Plan.$name }
    if ($Plan.BinaryPath -ieq $Plan.ConfigPath -or $Plan.BinaryPath -notmatch '\.exe$') { throw 'Binary and configuration must be distinct; binary must be an exe.' }
    foreach ($path in @([IO.Path]::GetDirectoryName($Plan.BinaryPath), [IO.Path]::GetDirectoryName($Plan.ConfigPath), $Plan.DataDirectory)) { Assert-MhProtected $path }
    foreach ($kind in @('Binary','Config')) {
        $expected = $Plan.('Expected' + $kind + 'Sha256')
        if ($expected -notmatch '^(ABSENT|[A-Fa-f0-9]{64})$') { throw 'Expected hashes must be SHA256 or ABSENT.' }
        $target = $Plan.($kind + 'Path')
        if ((Get-MhHash $target) -ne $expected) { throw "File changed since review: $target" }
        if ($expected -ne 'ABSENT') { Assert-MhProtected $target }
        $source = $Plan.('Candidate' + $kind + 'Path')
        if ($source) {
            $source = Get-MhPath $source
            $Plan.('Candidate' + $kind + 'Path') = $source
            if ($source -in @($Plan.BinaryPath, $Plan.ConfigPath)) { throw 'Stage candidates separately from live files.' }
            if ($Plan.('Candidate' + $kind + 'Sha256') -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-MhHash $source) -ne $Plan.('Candidate' + $kind + 'Sha256')) { throw 'Candidate digest mismatch.' }
        } elseif ($expected -eq 'ABSENT') { throw 'A missing target needs a candidate.' }
    }
    if ($Plan.TaskName -match '[*?\[\]]' -or $Plan.TaskPath -match '[*?\[\]]' -or $Plan.TaskPath -notmatch '^\\.*\\$|^\\$') { throw 'Use exact task names and paths without wildcards.' }
}
function Invoke-MhApply([string]$PlanFile, [string]$Root) {
    $plan = Get-Content -LiteralPath $PlanFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-MhPlan $plan
    $lock = [IO.File]::Open((Join-Path $Root ((Get-MhTextHash $plan.BinaryPath.ToLowerInvariant()) + '.lock')), 'OpenOrCreate', 'ReadWrite', 'None')
    $directory = $null; $state = $null
    try {
        foreach ($folder in Get-ChildItem -LiteralPath $Root -Directory) {
            $stateFile = Join-Path $folder.FullName 'state.json'
            if (Test-Path -LiteralPath $stateFile) {
                $other = Read-MhState $folder.FullName
                if ($other.Plan.BinaryPath -ieq $plan.BinaryPath -and $other.Phase -notin @('Committed','RolledBack')) { throw "Resolve the pending transaction first: $($folder.FullName)" }
            }
        }
        $directory = Join-Path $Root ([guid]::NewGuid().ToString('N'))
        New-MhPrivateDirectory $directory
        $instance = Get-MhInstance $plan
        $task = Get-MhTask $plan
        $state = [pscustomobject]@{
            OwnerSid=$script:OwnerSid; Plan=$plan; Task=$task; WasRunning=[bool]$instance; InstanceKey=(Get-MhInstanceKey $instance)
            Phase='Prepared'; Mutating=$false; Files=@(); DeadlineUtc=[DateTime]::UtcNow.AddSeconds($plan.RollbackAfterSeconds).ToString('o')
            Watchdog=('MihomoHelperRollback-' + [IO.Path]::GetFileName($directory))
        }
        foreach ($kind in @('Binary','Config')) {
            $target = $plan.($kind + 'Path'); $source = $plan.('Candidate' + $kind + 'Path')
            $before = $plan.('Expected' + $kind + 'Sha256')
            $backup = Join-Path $directory ($kind + '.before')
            if ($before -ne 'ABSENT') {
                [IO.File]::Copy($target, $backup, $false)
                if ((Get-MhHash $backup) -ne $before) { throw 'Source changed during snapshot.' }
            }
            $stage = Join-Path $directory $(if ($kind -eq 'Binary') { 'candidate.exe' } else { 'candidate.yml' })
            $after = $before
            if ($source) { $after = $plan.('Candidate' + $kind + 'Sha256') } else { $source = $target }
            [IO.File]::Copy($source, $stage, $false)
            if ((Get-MhHash $stage) -ne $after) { throw 'Candidate changed while staging.' }
            $state.Files += [pscustomobject]@{ Target=$target; Before=$before; After=$after; Backup=$backup; Stage=$stage; Change=[bool]$plan.('Candidate' + $kind + 'Path'); Touched=$false }
        }
        Save-MhState $state $directory
        $validation = Join-Path $directory 'validation'; New-MhPrivateDirectory $validation
        $test = New-Object Diagnostics.Process
        $test.StartInfo.FileName = Join-Path $directory 'candidate.exe'
        $test.StartInfo.Arguments = '-t -d "{0}" -f "{1}"' -f $validation, (Join-Path $directory 'candidate.yml')
        $test.StartInfo.WorkingDirectory = $validation
        $test.StartInfo.UseShellExecute = $false; $test.StartInfo.CreateNoWindow = $true
        $test.StartInfo.RedirectStandardOutput = $true; $test.StartInfo.RedirectStandardError = $true
        try {
            if (!$test.Start()) { throw 'Candidate validation process did not start.' }
            $stdout = $test.StandardOutput.ReadToEndAsync(); $stderr = $test.StandardError.ReadToEndAsync()
            if (!$test.WaitForExit(30000)) { $test.Kill(); $test.WaitForExit(); throw 'Candidate -t exceeded 30 seconds.' }
            [IO.File]::WriteAllText((Join-Path $directory 'validation.stdout'), $stdout.GetAwaiter().GetResult())
            [IO.File]::WriteAllText((Join-Path $directory 'validation.stderr'), $stderr.GetAwaiter().GetResult())
            if ($test.ExitCode -ne 0) { throw 'Candidate -t failed; inspect the protected validation logs.' }
        } finally { $test.Dispose() }
        $state.DeadlineUtc = [DateTime]::UtcNow.AddSeconds($plan.RollbackAfterSeconds).ToString('o'); Save-MhState $state $directory
        $runner = Join-Path $directory 'Invoke-MihomoChange.ps1'; [IO.File]::Copy($script:EntryPath, $runner, $false)
        $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $action = New-ScheduledTaskAction -Execute $powershell -Argument ('-NoProfile -NonInteractive -File "{0}" -Mode Watchdog -TransactionPath "{1}"' -f $runner, $directory) -WorkingDirectory $directory
        $trigger = New-ScheduledTaskTrigger -Once -At ([datetime]::Parse($state.DeadlineUtc).ToLocalTime())
        $principal = New-ScheduledTaskPrincipal -UserId $script:OwnerSid -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 35) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
        Register-ScheduledTask -TaskName $state.Watchdog -TaskPath '\' -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
        Start-ScheduledTask -TaskName $state.Watchdog -TaskPath '\'
        $readyLimit = [DateTime]::UtcNow.AddSeconds(10)
        while (!(Test-Path -LiteralPath (Join-Path $directory 'guardian.ready'))) {
            if ([DateTime]::UtcNow -ge $readyLimit) { throw 'Guardian did not start; no live files will be changed.' }
            Start-Sleep -Milliseconds 200
        }
        if ([DateTime]::UtcNow -ge [datetime]::Parse($state.DeadlineUtc).ToUniversalTime()) { throw 'Rollback deadline already elapsed.' }
        if ([string](Get-ScheduledTask -TaskName $state.Watchdog -TaskPath '\').State -ne 'Running') { throw 'Guardian exited before mutation.' }
        Assert-MhPlan $plan; Assert-MhTaskUnchanged $state
        if ($task -and (Get-MhTask $plan).Enabled -ne $task.Enabled) { throw 'Task enabled state changed concurrently.' }
        if ((Get-MhInstanceKey (Get-MhInstance $plan)) -ne $state.InstanceKey) { throw 'Running instance changed during preflight.' }
        $state.Mutating=$true; $state.Phase='Applying'; Save-MhState $state $directory
        Stop-MhInstance $state
        foreach ($file in $state.Files) {
            if ($file.Change) {
                if ((Get-MhHash $file.Target) -ne $file.Before -or (Get-MhHash $file.Stage) -ne $file.After) { throw 'File conflict immediately before replacement.' }
                $file.Touched=$true; Save-MhState $state $directory
                Set-MhFile $file.Stage $file.Target
            }
        }
        Resume-MhInstance $state ($state.WasRunning -or $plan.StartAfterChange)
        $state.Phase='PendingValidation'; Save-MhState $state $directory
        return [pscustomobject]@{ TransactionPath=$directory; Phase=$state.Phase; DeadlineUtc=$state.DeadlineUtc }
    } catch {
        $failure = $_
        if ($state -and $directory) { Restore-MhTransaction $state $directory }
        throw "Change failed; transaction $directory. $($failure.Exception.Message)"
    } finally { $lock.Dispose() }
}
function Invoke-MhMain {
    if ($env:OS -ne 'Windows_NT' -or $PSVersionTable.PSEdition -ne 'Desktop') { throw 'This transaction runner requires Windows PowerShell 5.1 on Windows.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $script:OwnerSid = $identity.User.Value
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if ($script:OwnerSid -eq 'S-1-5-18' -or !$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run elevated as the target interactive user, not SYSTEM.' }
    $root = Join-Path $env:ProgramData 'MihomoHelperTransactions'; New-MhPrivateDirectory $root
    if ($Mode -eq 'Apply') {
        if (!$PlanPath) { throw 'Apply requires PlanPath.' }
        Invoke-MhApply (Get-MhPath $PlanPath) $root
        return
    }
    $directory = Get-MhPath $TransactionPath
    if ([IO.Path]::GetDirectoryName($directory) -ine $root) { throw 'Transaction must be a direct child of the protected transaction root.' }
    $state = Read-MhState $directory
    if ($Mode -eq 'Watchdog') {
        [IO.File]::WriteAllText((Join-Path $directory 'guardian.ready'), [string]$PID)
        while ([DateTime]::UtcNow -lt [datetime]::Parse($state.DeadlineUtc).ToUniversalTime()) {
            if ((Read-MhState $directory).Phase -in @('Committed','RolledBack')) { return }
            Start-Sleep -Seconds 1
        }
    }
    $lock = [IO.File]::Open((Join-Path $root ((Get-MhTextHash $state.Plan.BinaryPath.ToLowerInvariant()) + '.lock')), 'OpenOrCreate', 'ReadWrite', 'None')
    try {
        $state = Read-MhState $directory
        if ($Mode -eq 'Commit') {
            if (!$ValidationPassed -or $state.Phase -ne 'PendingValidation') { throw 'Commit requires PendingValidation and an explicit ValidationPassed assertion after real checks.' }
            if ([DateTime]::UtcNow -ge [datetime]::Parse($state.DeadlineUtc).ToUniversalTime()) { Restore-MhTransaction $state $directory; throw 'Deadline elapsed; transaction rolled back, not committed.' }
            Assert-MhTaskUnchanged $state
            foreach ($file in $state.Files) { if ((Get-MhHash $file.Target) -ne $file.After) { throw 'Files changed after Apply; cannot commit.' } }
            if ($state.Task -and (Get-MhTask $state.Plan).Enabled -ne $state.Task.Enabled) { throw 'Task enabled state changed after Apply.' }
            if (($state.WasRunning -or $state.Plan.StartAfterChange) -and !(Get-MhInstance $state.Plan)) { throw 'Expected instance is not running.' }
            $state.Phase='Committed'; Save-MhState $state $directory; Remove-MhWatchdog $state
        } else { Restore-MhTransaction $state $directory }
        [pscustomobject]@{ TransactionPath=$directory; Phase=$state.Phase }
    } finally { $lock.Dispose() }
}
# Dot-sourcing only exposes helpers for tests and read-only discovery.
if ($MyInvocation.InvocationName -ne '.') { Invoke-MhMain }
