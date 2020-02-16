$text = Get-Content -Path C:\Users\david\git\musictoday\sample.txt
function processMultipleBOMs {
    param ($bomNames)
    $numberOfCDs = 0

    foreach( $bomName in $bomNames ) {
        if( $bomName -match '.+CD.+' ) {
            $numberOfCDs += [int]$bomName.split( "-" )[1]
        } else {
            return $false
        }
    }
    if( $numberOfCDs -gt 2 ) {
        return $false
    } else {
        return $true
    }

}
foreach( $x in $text ) {
    if($x -like '*batch_id*') {
        continue
    }

    $arr = $x.split(",")
    $bid = $arr[0]
    $bnm = $arr[1]

    $printcfm = $true

    if( $bnm -match 'NOCFM' ) {
        $printcfm = $false

    } elseif( ([regex]::Matches($bnm, "-" )).count -gt 1) {
        $bnmArray = $bnm.split( " " )
        $printcfm = processMultipleBOMs( $bnmArray )

    } elseif( $bnm -match '^([^-]+CD[^-]+-[12])$' ) {
        $printcfm = $true
    } else {
        $printcfm = $false
    }

    if( $printcfm ) {
        Write-Output "$bnm print to CFM"
    } else {
        Write-Output "$bnm do NOT print to CFM"
    }

}

