# NEO4J-PowerShell-Driver
A PowerShell implementation of the NEO4J .net Driver.
***Special Thanks to: @glennsarti & @cskardon ***

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
         Write-Host ($result | ConvertTo-JSON -Depth 20)

        # Advanced Query with parameters --------------------------------------------------
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
         $CYPHER_PARAM.Add('props', $listForUnwind)
    
         $result = $N4J_Connection.Run($query, $CYPHER_PARAM)
         Write-Host ($result | ConvertTo-JSON -Depth 10)

    .NOTES

        ***Special Thanks to: @glennsarti & @cskardon for the help with .net data types for
        the .net Driver intergration when my brain stoped working.***

#>
