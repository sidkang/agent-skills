#requires -Version 5.1
# Run only on a disposable, elevated, logged-in Windows test account.
# Uses a no-network fixture executable, never mihomo, TUN or real subscriptions.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runner = (Resolve-Path (Join-Path $PSScriptRoot '..\scripts\Invoke-MihomoChange.ps1')).Path
$tokens = $null; $parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
. $runner
$script:OwnerSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -or $PSVersionTable.PSEdition -ne 'Desktop') { throw 'Tests require elevated Windows PowerShell 5.1.' }
$root = Join-Path $env:ProgramData ('MihomoHelperTest-' + [guid]::NewGuid().ToString('N'))
New-MhPrivateDirectory $root
$fixture = Join-Path $root 'fixture.exe'
$source = @'
using System;
using System.IO;
using System.Threading;
public class MhFixture {
    public static int Main(string[] args) {
        int index = Array.IndexOf(args, "-f");
        string config = index >= 0 ? File.ReadAllText(args[index + 1]) : "";
        if (Array.IndexOf(args, "-t") >= 0) return config.Contains("invalid") ? 2 : 0;
        if (config.Contains("exit-on-start")) return 3;
        while (true) Thread.Sleep(1000);
    }
}
'@
Add-Type -TypeDefinition $source -OutputAssembly $fixture -OutputType ConsoleApplication
$cases = New-Object Collections.Generic.List[object]
$tasks = New-Object Collections.Generic.List[string]
$script:passed = 0

function Assert-Test([bool]$Condition, [string]$Message) { if (!$Condition) { throw $Message } }
function Expect-Failure([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true }
    Assert-Test $failed $Message
}
function Write-Plan($Case) {
    [IO.File]::WriteAllText($Case.PlanPath, ($Case.Plan | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
}
function New-Case([string]$Name, [bool]$Running = $false) {
    $dir = Join-Path $root $Name; New-MhPrivateDirectory $dir
    $exe = Join-Path $dir ('mh-' + $Name + '.exe')
    Copy-Item -LiteralPath $fixture -Destination $exe
    $config = Join-Path $dir 'config.yml'; [IO.File]::WriteAllText($config, 'before')
    $candidate = Join-Path $dir 'candidate.yml'; [IO.File]::WriteAllText($candidate, 'after')
    $plan = [pscustomobject]@{
        BinaryPath=$exe; ConfigPath=$config; DataDirectory=$dir
        ExpectedBinarySha256=(Get-MhHash $exe); ExpectedConfigSha256=(Get-MhHash $config)
        CandidateBinaryPath=''; CandidateBinarySha256=''
        CandidateConfigPath=$candidate; CandidateConfigSha256=(Get-MhHash $candidate)
        TaskName=''; TaskPath='\'; StartAfterChange=$false; RollbackAfterSeconds=120
    }
    $case = [pscustomobject]@{ Name=$Name; Plan=$plan; PlanPath=(Join-Path $dir 'plan.json'); Transaction=''; Caller=$null }
    $cases.Add($case)
    Write-Plan $case
    if ($Running) {
        Start-Process -FilePath $exe -ArgumentList (Get-MhArguments $plan) -WorkingDirectory $dir -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 1
        Assert-Test ([bool](Get-MhInstance $plan)) 'Initial fixture failed to run.'
    }
    return $case
}
function Apply-Case($Case) {
    Write-Plan $Case
    $result = & $runner -Mode Apply -PlanPath $Case.PlanPath
    $Case.Transaction = $result.TransactionPath
    Assert-Test ($result.Phase -eq 'PendingValidation') 'Apply did not await validation.'
}
function Pass-Test([string]$Name) { $script:passed++; Write-Host "PASS: $Name" }

try {
    $case = New-Case 'conflict'
    [IO.File]::WriteAllText($case.Plan.ConfigPath, 'user-edit')
    Expect-Failure { & $runner -Mode Apply -PlanPath $case.PlanPath } 'Concurrent file change was not detected.'
    Assert-Test ((Get-Content -LiteralPath $case.Plan.ConfigPath -Raw) -eq 'user-edit') 'Concurrent edit overwritten.'
    Pass-Test 'stale plan stops before mutation'

    $case = New-Case 'preflight' $true
    $oldKey = Get-MhInstanceKey (Get-MhInstance $case.Plan)
    [IO.File]::WriteAllText($case.Plan.CandidateConfigPath, 'invalid')
    $case.Plan.CandidateConfigSha256 = Get-MhHash $case.Plan.CandidateConfigPath; Write-Plan $case
    Expect-Failure { & $runner -Mode Apply -PlanPath $case.PlanPath } 'Invalid candidate passed preflight.'
    Assert-Test ((Get-MhInstanceKey (Get-MhInstance $case.Plan)) -eq $oldKey) 'Preflight failure interrupted old core.'
    Assert-Test ((Get-MhHash $case.Plan.ConfigPath) -eq $case.Plan.ExpectedConfigSha256) 'Preflight modified config.'
    Pass-Test 'failed -t preserves running instance'

    $case = New-Case 'ambiguous' $true
    $alternate = Join-Path $case.Plan.DataDirectory 'config.yaml'
    [IO.File]::WriteAllText($alternate, 'before')
    $case.Plan.ConfigPath = $alternate; Write-Plan $case
    Expect-Failure { & $runner -Mode Apply -PlanPath $case.PlanPath } 'Wrong -f path was accepted.'
    $case.Plan.ConfigPath = Join-Path $case.Plan.DataDirectory 'config.yml'
    Assert-Test ([bool](Get-MhInstance $case.Plan)) 'Wrong-config check stopped the real instance.'
    Pass-Test 'explicit -f must match actual instance'

    $case = New-Case 'commit'
    Apply-Case $case
    Assert-Test (!(Get-MhInstance $case.Plan)) 'Originally stopped instance was started.'
    Expect-Failure { & $runner -Mode Commit -TransactionPath $case.Transaction } 'Commit did not require validation assertion.'
    $result = & $runner -Mode Commit -TransactionPath $case.Transaction -ValidationPassed
    Assert-Test ($result.Phase -eq 'Committed') 'Commit failed.'
    Assert-Test ((Get-MhHash $case.Plan.ConfigPath) -eq $case.Plan.CandidateConfigSha256) 'Candidate not committed.'
    Pass-Test 'explicit commit and stopped-state preservation'

    $case = New-Case 'disabled' $true
    $taskName = 'MihomoHelperTest-' + [guid]::NewGuid().ToString('N'); $tasks.Add($taskName)
    $action = New-ScheduledTaskAction -Execute $case.Plan.BinaryPath -Argument (Get-MhArguments $case.Plan) -WorkingDirectory $case.Plan.DataDirectory
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId $script:OwnerSid -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Principal $taskPrincipal | Out-Null
    Disable-ScheduledTask -TaskName $taskName | Out-Null
    $case.Plan.TaskName = $taskName
    Apply-Case $case
    Assert-Test (!(Get-ScheduledTask -TaskName $taskName).Settings.Enabled) 'Apply enabled a disabled task.'
    $result = & $runner -Mode Rollback -TransactionPath $case.Transaction
    Assert-Test ($result.Phase -eq 'RolledBack') 'Rollback failed.'
    Assert-Test (!(Get-ScheduledTask -TaskName $taskName).Settings.Enabled) 'Rollback enabled a disabled task.'
    Assert-Test ([bool](Get-MhInstance $case.Plan)) 'Original manual instance was not restored.'
    Pass-Test 'disabled task stays disabled while manual instance is restored'

    $case = New-Case 'startup' $true
    [IO.File]::WriteAllText($case.Plan.CandidateConfigPath, 'exit-on-start')
    $case.Plan.CandidateConfigSha256 = Get-MhHash $case.Plan.CandidateConfigPath; Write-Plan $case
    Expect-Failure { & $runner -Mode Apply -PlanPath $case.PlanPath } 'Failed new process was accepted.'
    Assert-Test ((Get-MhHash $case.Plan.ConfigPath) -eq $case.Plan.ExpectedConfigSha256) 'Startup failure did not restore configuration.'
    Assert-Test ([bool](Get-MhInstance $case.Plan)) 'Startup failure did not restore old process.'
    Pass-Test 'post-replacement startup failure restores old instance'

    $case = New-Case 'recovery-conflict'
    Apply-Case $case
    [IO.File]::WriteAllText($case.Plan.ConfigPath, 'new-user-edit')
    Expect-Failure { & $runner -Mode Rollback -TransactionPath $case.Transaction } 'Recovery overwrote a concurrent edit.'
    Assert-Test ((Get-Content -LiteralPath $case.Plan.ConfigPath -Raw) -eq 'new-user-edit') 'User edit lost during recovery.'
    Assert-Test ((Read-MhState $case.Transaction).Phase -eq 'RecoveryFailed') 'Recovery conflict falsely reported success.'
    # Explicit test-only conflict resolution, followed by a normal recovery retry.
    Copy-Item -LiteralPath $case.Plan.CandidateConfigPath -Destination $case.Plan.ConfigPath -Force
    & $runner -Mode Rollback -TransactionPath $case.Transaction | Out-Null
    Pass-Test 'recovery conflict is retained, reported, and retryable'

    $case = New-Case 'caller-death' $true
    $case.Plan.RollbackAfterSeconds = 30; Write-Plan $case
    $callerScript = Join-Path $case.Plan.DataDirectory 'caller.ps1'
    $callerBody = "& '" + $runner.Replace("'", "''") + "' -Mode Apply -PlanPath '" + $case.PlanPath.Replace("'", "''") + "' | Out-Null`nStart-Sleep -Seconds 120`n"
    [IO.File]::WriteAllText($callerScript, $callerBody, (New-Object Text.UTF8Encoding($false)))
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $case.Caller = Start-Process -FilePath $powershell -ArgumentList ('-NoProfile -NonInteractive -File "{0}"' -f $callerScript) -PassThru -WindowStyle Hidden
    $limit = [DateTime]::UtcNow.AddSeconds(60)
    $found = $false
    while ([DateTime]::UtcNow -lt $limit) {
        foreach ($folder in Get-ChildItem -LiteralPath (Join-Path $env:ProgramData 'MihomoHelperTransactions') -Directory) {
            if (!(Test-Path -LiteralPath (Join-Path $folder.FullName 'state.json'))) { continue }
            $state = Read-MhState $folder.FullName
            if ($state.Plan.BinaryPath -eq $case.Plan.BinaryPath) {
                $case.Transaction = $folder.FullName
                if ($state.Mutating -and $state.Files[1].Touched -and (Get-MhHash $case.Plan.ConfigPath) -eq $case.Plan.CandidateConfigSha256) { $found = $true; break }
                if ($state.Phase -in @('RolledBack','RecoveryFailed')) { throw "Caller failed before interruption: $($state.Phase)" }
            }
        }
        if ($found) { break }
        Start-Sleep -Milliseconds 100
    }
    Assert-Test $found 'Could not observe mutation before killing caller.'
    if (!$case.Caller.HasExited) { $case.Caller.Kill(); $case.Caller.WaitForExit() }
    $limit = [DateTime]::UtcNow.AddSeconds(100)
    do {
        Start-Sleep -Milliseconds 500
        $state = Read-MhState $case.Transaction
    } while ($state.Phase -notin @('RolledBack','RecoveryFailed') -and [DateTime]::UtcNow -lt $limit)
    Assert-Test ($state.Phase -eq 'RolledBack') "Independent guardian failed: $($state.Phase)"
    Assert-Test ((Get-MhHash $case.Plan.ConfigPath) -eq $case.Plan.ExpectedConfigSha256) 'Guardian failed to restore old config.'
    Assert-Test ([bool](Get-MhInstance $case.Plan)) 'Guardian failed to restore old instance.'
    Pass-Test 'independent watchdog survives caller termination after mutation'

    Write-Host "Windows transaction checks passed: $script:passed"
} finally {
    # Clean only exact fixture paths and task names created by this test run.
    foreach ($case in $cases) {
        if ($case.Caller -and !$case.Caller.HasExited) { $case.Caller.Kill(); $case.Caller.WaitForExit() }
        if ($case.Transaction -and (Test-Path -LiteralPath $case.Transaction)) {
            $state = Read-MhState $case.Transaction
            if ($state.Phase -notin @('Committed','RolledBack')) {
                try { & $runner -Mode Rollback -TransactionPath $case.Transaction | Out-Null } catch { Write-Warning $_ }
            }
            $state = Read-MhState $case.Transaction
            if ($state.Phase -in @('Committed','RolledBack')) { Remove-MhWatchdog $state }
        }
        $instance = Get-MhInstance $case.Plan
        if ($instance) { Stop-Process -Id $instance.ProcessId -Force }
    }
    foreach ($task in $tasks) { Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue }
    # Snapshots are intentionally retained for CI diagnostics; the disposable VM is destroyed afterwards.
    Write-Host "Fixture directory retained: $root"
}
