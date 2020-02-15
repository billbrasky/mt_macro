Add-Type -AssemblyName System.Windows.Forms

$x = [System.Windows.Forms.Cursor]::Position.X
$y = [System.Windows.Forms.Cursor]::Position.Y
$counter = 0
Do {
    $X = [System.Windows.Forms.Cursor]::Position.X
    $Y = [System.Windows.Forms.Cursor]::Position.Y
    Write-Output "X: $X | Y: $Y"
    # Write-Output "X: $X | Y: $Y | $counter | $x"
    # if($X -eq $x) {
    #     Write-Output "$counter"
    #     $counter += 1
    # }else {
    #     $counter += 1
    #     $x = $X
    # }
} Until ($counter -eq 50)
