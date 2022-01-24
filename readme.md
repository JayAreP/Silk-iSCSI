# Silk iSCSI Services Connection Module (SISCM)
This module is a wrapper for the native iSCSI and MPIO powershell modules, created to help ease the management connections and sessions to Silk SDP CNodes. 

### Installation 
Manually install
```powershell
Import-Module ./path/SilkiSCSI/SilkiSCSI.psd1
```

Or install via the PowerShell Gallery
```powershell
Find-Module SilkiSCSI | Install-Module -confirm:0
```

Or, run the provided InstallSilkiSCSI.ps1 script. 
```powershell
Unblock-File .\InstallSilkiSCSI.ps1
.\InstallSilkiSCSI.ps1
```
Which gives you a simple install menu. 
```powershell
------
1. C:\Users\user\Documents\PowerShell\Modules
2. C:\Program Files\PowerShell\Modules
3. c:\program files\powershell\7\Modules
4. C:\Program Files (x86)\WindowsPowerShell\Modules
5. C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
------
Select Install location:
```

### Example usage: 



You can then use the functions in the module manifest to perform the desired operations. 
```Powershell
# Get existing Silk iscsi sessions
Get-SilkSessions | ft

CNode IP   Host IP   Configured Sessions Connected Sessions Silk IQN
--------   -------   ------------------- ------------------ --------
10.12.0.21 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801
```

```Powershell
# Connect sessions to cnode
Connect-SilkCNode -cnodeIP 10.12.0.20 -sessionCount 12

CNode IP   Host IP   Configured Sessions Connected Sessions Silk IQN
--------   -------   ------------------- ------------------ --------
10.12.0.20 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801
10.12.0.21 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801
```

```Powershell
# Disconnect all sessions from cnode
Disconnect-SilkCNode -cnodeIP 10.12.0.21

CNode IP   Host IP   Configured Sessions Connected Sessions Silk IQN
--------   -------   ------------------- ------------------ --------
10.12.0.20 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801
```

```Powershell
# Connect sessions to cnode and automatically re-balance
# SHow current sessions:
Get-SilkSessions | ft

CNode IP   Host IP   Configured Sessions Connected Sessions Silk IQN
--------   -------   ------------------- ------------------ --------
10.12.0.20 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801
10.12.0.21 10.12.1.6                  12                 12 iqn.2009-01.com.kaminario:storage.k2.1077801

# Add 3rd c-node and re-balance
Connect-SilkCNode -cnodeIP 10.12.0.22 -rebalance

CNode IP   Host IP   Configured Sessions Connected Sessions Silk IQN
--------   -------   ------------------- ------------------ --------
10.12.0.20 10.12.1.6                   8                  8 iqn.2009-01.com.kaminario:storage.k2.1077801
10.12.0.21 10.12.1.6                   8                  8 iqn.2009-01.com.kaminario:storage.k2.1077801
10.12.0.22 10.12.1.6                   8                  8 iqn.2009-01.com.kaminario:storage.k2.1077801
```

```Powershell
# Show the hard connection status for each disk being serviced. 
Get-SilkDisks

Number SerialNumber 10.12.0.20 10.12.0.21
------ ------------ ---------- ----------
     2 1072290000           12         12
     3 107229000d           12         12
     4 107229000e           12         12
     5 107229000f           12         12
```
