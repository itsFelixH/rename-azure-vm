# Renaming Azure VMs is not allowed, so we will backup and delete the old VM and create an new VM with the desired name. 


# BACK UP VM PROPERTIES
# Resource Group Name
$ResourceGroupName = 'RG_order_management'

# (Current) Virtual Machine Name
$VirtualMachineName = 'VM_order_management_OLD'

# VM properties
Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName | Export-Clixml C:\VM_order_management_BACKUP.xml -Depth 5

# Import VM settings from backup XML and store it in a variable
$backupVM = Import-Clixml C:\VM_order_management_BACKUP.xml


# DELETE OLD VM
Remove-AzVM -ResourceGroupName $backupVM.ResourceGroupName -Name $backupVM.Name


# CREATE NEW (RENAMED) VM
# Set the name of the new virtual machine
$newVMName = 'VM_order_management_RENAMED'

# Initiate a new virtual machine configuration
$newVM = New-AzVMConfig -VMName $newVMName -VMSize $backupVM.HardwareProfile.VmSize -Tags $backupVM.Tags

# Attach the OS Disk of the old VM to the new VM
Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $backupVM.StorageProfile.OsDisk.ManagedDisk.Id -Name $backupVM.StorageProfile.OsDisk.Name -Windows

# Attach all NICs of the old VM to the new VM
$backupVM.NetworkProfile.NetworkInterfaces | % {Add-AzVMNetworkInterface -VM $newVM -Id $_.Id}

# Attach all Data Disks (if any) of the old VM to the new VM
$backupVM.StorageProfile.DataDisks | % {Add-AzVMDataDisk -VM $newVM -Name $_.Name -ManagedDiskId $_.ManagedDisk.Id -Caching $_.Caching -Lun $_.Lun -DiskSizeInGB $_.DiskSizeGB -CreateOption Attach}

# Create the new virtual machine
New-AzVM -ResourceGroupName $ResourceGroupName -Location $backupVM.Location -VM $newVM

# Confirm existence of the new VM 
Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $newVMName