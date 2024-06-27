Import-Module -Name az

# General values
$subscriptionId = '31076e3c-fc5e-4f0b-be52-0eb744e89036'
$resourceGroupName ='AVD-Processing-RG'
$location = 'IsraelCentral' 

# VMs' values
$vmName = 'pavd-proc-23'
$cleanVM = 'pavd-proc-10'
$snapshotName = $vmName + '-snap'

# Disks' values
$oldDisk = $vmName + '_OsDisk'
$diskName = $snapshotName + '_OsDisk'
$diskSize = '128'
$storageType = 'StandardSSD_ZRS'
$zone=2

# Set desired subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Create disk snapshot 
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

# Create disk from snapshot
$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
$diskConfig = New-AzDiskConfig -SkuName $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id -DiskSizeGB $diskSize
Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Force
New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $diskName

# Attach new disk
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $cleanVM
$disk = Get-AzDisk -ResourceGroupName $resourceGroupName -Name $diskName
$vm = Add-AzVMDataDisk -VM $vm -Name $diskName -CreateOption Attach -ManagedDiskId $disk.Id -Lun 1

# Finishing touches
Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm
Start-AzVM -Name $vm.Name -ResourceGroupName $resourceGroupName