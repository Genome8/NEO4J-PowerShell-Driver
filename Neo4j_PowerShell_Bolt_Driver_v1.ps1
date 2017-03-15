

Function NEO4J-Bolt-Connect
{
<#
    .SYNOPSIS

        Creates a .NET Bolt Connection to a NEO4J Database for Queries.

        Author: Larry Cummings (@genome_8 on neo4j-users.slack.com)
        License: MIT License
        Required Dependencies: Neo4j.Driver.dll, Sockets.Plugin.Abstractions.dll `
            , Sockets.Plugin.dll, .NET 4.5 tested on WIndows 10 & Server 2012 w/
            .net 4.6.2 installed but the Driver can be adapted for .net 3.5 with 
            some modifications. https://github.com/neo4j/neo4j-dotnet-driver
        Optional Dependencies: 

    .DESCRIPTION

        Allows Powershell to connect to NEO4j Databases using the BOLT Protocall
        via the NEO4J .net driver functions in PowerShell. After providing
        the required Dependencies and paramaters This function will return the 
        authorization token and Driver to Query the NEO4J Database.
      
    .PARAMETER User_ID

        The User Name for your NEO4J Connection.

    .PARAMETER User_Password

        The Password in String format for your NEO4J Connection.

    .PARAMETER Server_Address

        The URL and Port to your NEO4J Connection.

    .EXAMPLE
        # First we need to connect to the DB
        $N4J_Connection = neo4j-Bolt-Connect -User_ID 'neo4j' -User_Password 'A_Secure_L0ng_P@$$w0Rd' -Server_Address 'BOLT://localhost:7687' (Optional -Verbose)

        # Ok, Great I can connect to the NEO4J Database, Now what?

        # Basic Query ---------------------------------------------------------------------
         $result = $N4J_Connection.Run('MATCH (n) RETURN n LIMIT 10')
         Write-Host ($result | ConvertTo-JSON -Depth 20)

        # Query with parameters -----------------------------------------------------------
         $CYPHER_PARAM = new-object 'system.collections.generic.dictionary[[string],[object]]'
         $CYPHER_PARAM.Add('limit', 10)

         $result = $N4J_Connection.Run('MATCH (n) RETURN n LIMIT {limit}', $CYPHER_PARAM )
         Write-Host ($result | ConvertTo-JSON -Depth 20)        # Advanced Query with parameters --------------------------------------------------
         # 1st., we must define the correct data type to pass to .net driver.
         $listForUnwind = new-object 'System.Collections.Generic.List[[object]]'

         # Next we build our Optimised Query for Bulk Insert.
         $query = 'UNWIND {props} AS
            prop MERGE (user:User {name:prop.account}) WITH user,
            prop MERGE (computer:Computer {name: prop.computer}) WITH user,computer,
            prop MERGE (computer)-[:HasSession {Weight : prop.weight}]-(user)'

         # Now we can add the data to the Prop's.
         $iprops = new-object 'system.collections.generic.dictionary[[string],[object]]'
         $iprops.Add('account', 'testAccount@Domain.com')
         $iprops.Add('computer', 'TestComputer@Domain.com')
         $iprops.Add('weight', '1') 

         # Here we are building the List Array.
         $listForUnwind.Add($iprops)

         # Lest add some more data for the example
         $iprops = new-object 'system.collections.generic.dictionary[[string],[object]]'
         $iprops.Add('account', 'testAccount_02@Domain.com')
         $iprops.Add('computer', 'TestComputer_02@Domain.com')
         $iprops.Add('weight', '1') 

         # And add more data to the List Array
         $listForUnwind.Add($iprops)

         # Finnaly we need to build the Props UNWIND for NEO4J
         $CYPHER_PARAM = new-object 'system.collections.generic.dictionary[[string],[object]]'
         $CYPHER_PARAM.Add('props', $listForUnwind)             $result = $N4J_Connection.Run($query, $CYPHER_PARAM)
         Write-Host ($result | ConvertTo-JSON -Depth 10)

    .NOTES

        ***Special Thanks to: @glennsarti & @cskardon for the help with .net data types for
        the .net Driver intergration when my brain stoped working.***

#>
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $User_ID,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $User_Password,

        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $Server_Address
    )

Write-Verbose "Building AuthToken for: $User_ID"
$authToken = [Neo4j.Driver.V1.AuthTokens]::Basic($User_ID,$User_Password)

Write-Verbose "Building .net DB Driver."
$dbDriver = [Neo4j.Driver.V1.GraphDatabase]::Driver($Server_Address,$authToken)

Write-Verbose "Getting Auth Token to: $Server_Address"
$session = $dbDriver.Session()
Write-Verbose "Connection returned: $($session.ID)"

return $session
}

# If the Drivers are located with the script then un comment else set Dir.
$Driver_Location = split-path -parent $MyInvocation.MyCommand.Definition
#$Driver_Location = 'C:\Users\SOMEUSER\Desktop\Folder'

Write-Verbose "Loading .net drivers from: $Driver_Location"
Add-Type -Path $($Driver_Location + '\Neo4j.Driver.dll')
Add-Type -Path $($Driver_Location + '\Sockets.Plugin.Abstractions.dll')
Add-Type -Path $($Driver_Location + '\Sockets.Plugin.dll')

# Lets build the connection
$N4J_Connection = NEO4J-Bolt-Connect -User_ID 'neo4j' -User_Password 'noe4jPASSWORD' -Server_Address 'bolt://localhost:7687' -Verbose

$result = $N4J_Connection.Run('MATCH (n) RETURN n LIMIT 10')
Write-Host ($result.Values | ConvertTo-JSON -Depth 10)

# When we are done Make sure to Close the connection so other can use the rescource pool
$N4J_Connection.Close()

# Lest take out the Garabage like a Good Child lol.
[System.GC]::Collect()
Write-Host 'fin'