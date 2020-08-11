function Get-VasttrafikBus {
    <#
    .SYNOPSIS
       Gets bus tables from Västtrafik.
    .DESCRIPTION
       Gets information about bus timetables from Västtrafiks API.
       User can specify destination and depature from, switch from depature to arrival time.
       User need to specify a authorization key from https://developer.vasttrafik.se/ and add it under "$AuthToken" variable.

       Credit to Philip Haglund who gave me inspiration.
    
   .Link
       API:     https://developer.vasttrafik.se/portal/#/api/Reseplaneraren/v2/landerss
       Creator: https://github.com/FilipCollin

    
    #>
    
        [Alias('bus')]
        [CmdletBinding()]
    
        param (
                     
             [Parameter(
                HelpMessage='Specify which bus stop you should depart from. Default value = Bergkristallsgatan',
                ValueFromPipeline=$true,
                Position = 0
             )]
             [string] $DepatureFrom = 'Bergkristallsgatan',
    
             [Parameter(
                HelpMessage='Specify the destination. Default value = Brunnsparken',
                ValueFromPipeline=$true,
                Position = 1
            )]
            [string] $Destination = 'Brunnsparken',
    
             [Parameter(
                HelpMessage='Enter the time. Example, 21:00. Default value = Current Time',
                ValueFromPipeline=$true,
                Position = 2
             )]
            [datetime] $Time = (Get-Date),

            [Parameter(
                HelpMessage='Outputs arrivaltime instead of depature time',
                ValueFromPipeline=$true,
                Position = 3
             )]
             [switch] $ArrivalTime,

             [Parameter(
                HelpMessage='Get the depature board for the specified bus stop',
                ValueFromPipeline=$true,
                Position = 4
             )]
             [switch] $Depatureboard
    
    )
    try {
        
    
            $AuthToken = Invoke-RestMethod -Method Post -Uri "https://api.vasttrafik.se:443/token" -Headers @{ 'Authorization' = 'Basic XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'} -ContentType "application/x-www-form-urlencoded" -Body @{ 'grant_type' = 'client_credentials'} -ErrorAction Stop
            
            $date = Get-Date
            $HourMinute = "{0:HH}:{0:mm}" -f $Time
            $Tomorrow = $date.AddDays(1)
            $TomorrowString = "{0:yyy}-{0:MM}-{0:dd}" -f $Tomorrow
            $dateString = "{0:yyyy}-{0:MM}-{0:dd}" -f $date

        if ($Depatureboard) {

            $Depatures = Invoke-RestMethod -Method Get -Uri "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?id=$DepatureFrom&date=$datestring&time=$HourMinute&format=json" -Headers @{ 'Authorization' = "Bearer $($AuthToken.access_token)"} -ErrorAction Stop
            $Depatures = $Depatures.DepartureBoard.Departure

            $Output = @()

            $Depatures | foreach {
            $AllInfo = [PSCustomObject]@{

                Depature      = $_.Time
                Date          = if ($_.Date -eq $TomorrowString){"$($_.Date) ($($Tomorrow.DayOfWeek))"} else {$_.Date}   
                Från          = $_.stop 
                Direction     = $_.Direction
                Name          = $_.Name -replace '[0-9]'
                Number        = $_.Sname
                Track         = $_.Track
                Type          = $_.Type
                

        }

             $Output += $AllInfo

        }
            $Output | Out-GridView -Title "Depatureborad from $($Depatures.stop[0])" -PassThru

        }
        else {
            
            $Depature = Invoke-RestMethod -Method Get -Uri "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?&format=json&jsonpCallback=processJSON&input=$DepatureFrom HTTP/1.1" -Headers @{ 'Authorization' = "Bearer $($AuthToken.access_token)"  } -ErrorAction Stop

            $Depature = $Depature -replace 'processJSON\(' -replace '\);'
            $Depature = ConvertFrom-Json $Depature
            $Depature = $Depature.LocationList.StopLocation | Select-Object -First 1

    
            $FinalDestination = Invoke-RestMethod -Method Get -Uri "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?&format=json&jsonpCallback=processJSON&input=$Destination HTTP/1.1" -Headers @{ 'Authorization' = "Bearer $($AuthToken.access_token)"  } -ErrorAction Stop

            $FinalDestination = $FinalDestination -replace 'processJSON\(' -replace '\);'
            $FinalDestination = ConvertFrom-Json $FinalDestination
            $FinalDestination = $FinalDestination.LocationList.StopLocation | Select-Object -First 1

        
        if ($ArrivalTime) {
                
            $Journey = Invoke-RestMethod -Method Get -Uri "https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=$($Depature.id)&destId=$($FinalDestination.id)&date$datestring&searchForArrival=$HourMinute&time=$HourMinute&format=json" -Headers  @{ 'Authorization' = "Bearer $($AuthToken.access_token)"  } -ErrorAction Stop
            $Journey = $Journey.TripList.trip.leg

            }

        else {
               
            $Journey = Invoke-RestMethod -Method Get -Uri "https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=$($Depature.id)&destId=$($FinalDestination.id)&date$dateString&time=$HourMinute&format=json" -Headers @{ 'Authorization' = "Bearer $($AuthToken.access_token)"  } -ErrorAction Stop
            $Journey = $Journey.TripList.trip.leg

        }
           
            $Output = @()

            $Journey | foreach {
            $AllInfo = [PSCustomObject]@{

                Depature            = $_.origin.time
                Arrival             = $_.destination.time
                Change              = if (($_.origin.name) -notlike "*$($Depature.name)*" -and ($_.destination.name) -notlike "*$($FinalDestination.name)*") {'Change to'} elseif (($_.destination.name) -like "*$($FinalDestination.name)*" -and ($_.origin.name) -like "*$($Depature.name)*" ) {''} elseif (($_.destination.name) -like "*$($FinalDestination.name)*" -and ($_.origin.name) -notlike "*$($DepatureFrom.name)*" ) {'Sista bytet'} elseif (($_.destination.name) -notlike "*$($FinalDestination.name)*" -and ($_.origin.name) -like "*$($DepatureFrom.name)*" ) {'Contains a change'} else {}
                Date                = if ($_.origin.date -eq $TomorrowString){"$($_.origin.date) ($($Tomorrow.DayOfWeek))"} else {$_.origin.date}   
                From                = $_.origin.Name
                Track               = $_.origin.Track
                To                  = $_.destination.name
                "Destination Track" = $_.destination.Track
                Name                = $_.Name -replace '[0-9]'
                Number              = $_.sname
                Direction           = $_.direction
                Type                = $_.Type
            
                

        }

             $Output += $AllInfo

        }

            $Output | Out-GridView -Title "$($Journey.origin.name[0]) to $($Journey.destination.name[0])" -PassThru
    }

}
    catch {

            Write-Warning -Message ('Error: "{0}". From Cmdlet "{1}".' -f $_.Exception.Message, $_.CategoryInfo.Activity)
            Write-Warning -Message "This may have been caused due to an invalid access token to Västtrafiks API."
            break

    }
}
