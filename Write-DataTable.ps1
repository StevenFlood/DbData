<#
.SYNOPSIS
Writes data only to SQL Server tables.
.DESCRIPTION
Writes data only to SQL Server tables. However, the data source is not limited to SQL Server; any data source can be used, as long as the data can be loaded to a DataTable instance or read with a IDataReader instance.
.INPUTS
None
    You cannot pipe objects to Write-DataTable
.OUTPUTS
None
    Produces no output
.EXAMPLE
$dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors"
Write-DataTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -Data $dt
This example loads a variable dt of type DataTable from query and write the datatable to another database
.NOTES
Write-DataTable uses the SqlBulkCopy class see links for additional information on this class.
Version History
v1.0   - Chad Miller - Initial release
v1.1   - Chad Miller - Fixed error message
v1.2   - B. Holliger - Adds column mapping according to source table, allows insertion of data if destination column count differs
.LINK
http://msdn.microsoft.com/en-us/library/30c3y597%28v=VS.90%29.aspx
#>

function Write-DataTable {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $ServerInstance,
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $Database,
        [Parameter(Position = 2, Mandatory = $true)]
        $SchemaName = "dbo",
        [Parameter(Position = 3, Mandatory = $true)]
        [string] $TableName,
        [Parameter(Position = 4, Mandatory = $true)]
        $Data,
        [Parameter(Position = 5, Mandatory = $false)]
        [string] $Username,
        [Parameter(Position = 6, Mandatory = $false)]
        [string] $Password,
        [Parameter(Position = 7, Mandatory = $false)]
        [int] $BatchSize = 50000,
        [Parameter(Position = 8, Mandatory = $false)]
        [int] $QueryTimeout = 0,
        [Parameter(Position = 9, Mandatory = $false)]
        [int] $ConnectionTimeout = 15
    )
    
    $conn = New-Object System.Data.SqlClient.SQLConnection

    if ($Username) { 
        $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout
    } else {
        $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
    }

    $conn.ConnectionString = $ConnectionString

    try {
        $conn.Open()
        $bulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") $connectionString
        $bulkCopy.DestinationTableName = '[' + $SchemaName + '].[' + $tableName + ']'
        # Set mappings according source table
        $data | Get-Member -MemberType Property | Select-Object -ExpandProperty Name | ForEach-Object {
            [void] $bulkCopy.ColumnMappings.Add('[' + $_ + ']', $_)
        }
        $bulkCopy.BatchSize = $BatchSize
        $bulkCopy.BulkCopyTimeout = $QueryTimeOut
        $bulkCopy.WriteToServer($Data)
        $conn.Close()
    } catch {
        $ex = $_.Exception
        Write-Error "$ex.Message"
        continue
    }
}
