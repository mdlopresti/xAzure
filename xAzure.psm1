enum Ensure {
    Present
    Absent
} 

[DscResource()]
class xAzureAffinityGroup {
    [DscProperty(key)]
    [string]$Name

    [DscProperty()]
    [ensure]$Ensure

    [DscProperty(Mandatory)]
    [string]$Location

    [DscProperty()]
    [ensure]$Description

    [DscProperty()]
    [ensure]$Label

    [void] Set() {
        switch ($this.Ensure) {
            'Present' {
                # Validate whether New or Set is required
                $Get = Get-TargetResource -Location $this.Location -Name $this.Name -ErrorAction SilentlyContinue 
            
                $PSBoundParameters.Remove('Ensure') | out-null

                if ($Get.Name -eq $this.Name) {
                    # Native Set cmdlet
                    $PSBoundParameters.Remove('Location') | out-null
                    Write-Verbose "Setting properties of existing Affinity Group: `"$($this.Name)`""
                    Write-Verbose 'Please be patient as the operation completes.'
                    $CurrentSubscription = Get-AzureSubscription -Current
                    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                    Set-AzureAffinityGroup @PSBoundParameters
                }
                else {
                    # Native New cmdlet
                    Write-Verbose "Creating new Affinity Group: `"$($this.Name)`""
                    Write-Verbose 'Please be patient as the operation completes.'
                    $CurrentSubscription = Get-AzureSubscription -Current
                    Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                    New-AzureAffinityGroup @PSBoundParameters
                }
            }
            'Absent' {
                Remove-AzureAffinityGroup $this.Name
            }
        }
    }

    [bool] Test() {
        $bool = $true

        # Output from Get-TargetResource
        $Get = Get-TargetResource -Location $this.Location -Name $this.Name -ErrorAction SilentlyContinue 

        # Removing Cmdlet parameters from output
        $PSBoundParameters.Remove('Ensure') | out-null
        $PSBoundParameters.Remove('Verbose') | out-null
        $PSBoundParameters.Remove('Debug') | out-null
        $PSBoundParameters.Remove('ErrorAction') | out-null

        # Compare dictionary and hash table
        switch ($this.Ensure) {
            'Present'{
                $bool = $true
            }
            'Absent'{
                $bool = $false
            }
        }

        $PSBoundParameters.keys | ForEach-Object {
            if ($PSBoundParameters[$_] -ne $Get[$_]) {
                switch ($Ensure) {
                    'Present'{
                        $bool = $false
                    }
                    'Absent'{
                        $bool = $true
                    }
                }
                write-verbose "$($_): $($PSBoundParameters[$_]) -ne `"$($Get[$_])`""
            }
        }
        return $bool
    }

    [xAzureAffinityGroup] Get() {
        $CurrentSubscription = Get-AzureSubscription -Current
        Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"

        # Native Get cmdlet
        $Get = Get-AzureAffinityGroup -Name $This.Name -ErrorAction SilentlyContinue
    
        # Build Hashtable from native cmdlet values
        If ($Get.Name -eq $this.Name) {
            $this.Ensure = 'Present'
        } Else {
            $this.Ensure = 'Absent'
        }
        $this.Location = $Get.Location
        $this.Name = $Get.Name
        $this.Description = $Get.Description
        $this.Label = $Get.Label

        return $this
    }
}

[DscResource()]
class xAzureQuickVM {
    [DscProperty(key)]
    [string]$Name

    [DscProperty()]
    [ensure]$Ensure

    [DscProperty()]
    [string]$ImageName

    [DscProperty(Mandatory)]
    [string]$ServiceName

    [DscProperty()]
    [bool]$Linux

    [DscProperty()]
    [string]$LinuxUser

    [DscProperty()]
    [bool]$Windows

    [DscProperty()]
    [string]$AdminUsername

    [DscProperty()]
    [string]$Password

    [DscProperty()]
    [string]$InstanceSize

    [void] Set() {
        # Removing parameters from output
        $PSBoundParameters.Remove('Ensure') | out-null
        $PSBoundParameters.Remove('Debug') | out-null
        $PSBoundParameters.Remove('ErrorAction') | out-null

        switch ($this.Ensure) {
            'Present' {
                # Native Set cmdlet
                Write-Verbose "Creating VM `"$this.Name`" in Microsoft Azure."
                Write-Verbose 'Please be patient as the operation completes.'
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                $PSBoundParameters['Password'] = $this.Password.GetNetworkCredential().Password
                New-AzureQuickVM @PSBoundParameters
            }
            'Absent' {
                # Native Set cmdlet
                Write-Verbose "Removing VM `"$this.Name`" from Azure."
                Write-Verbose 'Please be patient as the operation completes.'
                $CurrentSubscription = Get-AzureSubscription -Current
                Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"
                Remove-AzureVM -Name $this.Name -ServiceName $this.ServiceName -DeleteVHD
            }
        }
    }

    [bool] Test() {
        $bool = $true
        # Output from Get-TargetResource
        $Get = Get-TargetResource -Name $this.Name -ServiceName $this.ServiceName -ErrorAction SilentlyContinue 

        switch ($this.Ensure) {
            'Present'{
                $bool = $true
            }
            'Absent'{
                $bool = $false
            }
        }

        if ($this.Name -ne $Get.Name -AND $this.ServiceName -ne $Get.ServiceName) {
            switch ($this.Ensure) {
                'Present'{
                    $bool = $false
                }
                'Absent'{
                    $bool = $true
                }
            }
            write-verbose 'The VM could not be found in Azure.'
        }

        return $bool
    }

    [xAzureQuickVM] Get() {
        $CurrentSubscription = Get-AzureSubscription -Current
        Write-Verbose "The Azure subscription ID is $($CurrentSubscription.SubscriptionID)"

        # Native Get cmdlet
        $Get = Get-AzureVM -Name $this.Name -ServiceName $this.ServiceName

        # Build Hashtable from native cmdlet values
        If ($Get.Name -eq $this.Name) {
            'Present'
        } Else {
            'Absent'
        }
        $this.Name = $Get.Name
        $this.ServiceName = $Get.ServiceName
            
        return $this
    }
}