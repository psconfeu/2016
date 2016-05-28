# beginning of data file
@{
AllNodes = @(
    @{
        NodeName = 'chefDemoNode'
        Roles = @('Web')

    },
    @{
        NodeName = 'server2'
        Roles = @('Hyper-V')
    },
    @{
        NodeName = '*'
        ExampleSoftware = @{
            Name = '7Zip'
            ProductId = '{23170F69-40C1-2702-1514-000001000000}'
            SourcePath = 'c:\Temp\7z1514-x64.msi'
        }
    }
);
    NonNodeData = @{
        ConfigFileContents = (Get-Content 'Config.xml')
    }
}
# ending of data file