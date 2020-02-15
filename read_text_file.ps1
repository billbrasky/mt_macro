$text = Get-Content -Path C:\Users\david\git\musictoday\sample.txt

foreach( $x in $text ) {
    if($x -like '*sample*') {
        continue
    }
    $filter = "Batch_ID = $x"
    Write-Output $filter
}