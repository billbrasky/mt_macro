$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{ 
    public int        type; // 0 = INPUT_MOUSE,
                            // 1 = INPUT_KEYBOARD
                            // 2 = INPUT_HARDWARE
    public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
    public int    dx ;
    public int    dy ;
    public int    mouseData ;
    public int    dwFlags;
    public int    time;
    public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void RightClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}
public static void LeftClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}
}
'@
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
#Send a click at a specified point


function processMultipleBOMs {
    param ( $bomNameString )
# When a BOM Name has more than one SKU pattern in it, it is processed here. All 
# SKUs are checked to verify if batch can be printed to the CFM or not.
# input: string
# return: boolean
	$numberOfCDs = 0
	$ht = @{}
	$bomNames = $bomNameString.split( "-" )

    foreach( $bomName in $bomNames ) {
        if( $bomName -match '.+CD.+' ) {
			$current = $bomName
			$ht[$bomName] = 0
		
		} elseif( $bomName.length -eq 1 ) {
			$ht[$current] += [int]$bomName
			$numberOfCDs += [int]$bomName
		
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
$homeDir = "C:\Users\breed\Documents"
$steps = Get-Content -Path "$homeDir\mt_macro-master\steps.txt"
$text = Get-Content -Path "$homeDir\mt_macro-master\data.txt"
$filterTemplate = "$homeDir\label_manager_filter_template.txt"
$filter = "$homeDir\label_manager_filter.txt"

# Loop through data source to organize CFM and non-CFM data. Also, order the 
# printing by largest to smallest.
$nocfm = @{}
$forcfm = @{}
foreach( $row in $text ) {
    if($row -like '*Batch ID*') {
        continue
    }

    $arr = $row.split(",")
    $bomName = $arr[4]
    $bid = $arr[0]
	
	if(( $null -eq $nocfm.$bid ) -and ( $null -eq $forcfm.$bid )) {

		$printcfm = $true

		if( $bomName -match 'NOCFM' ) {
			$printcfm = $false

		} elseif(( [regex]::Matches( $bomName, "-" )).count -gt 1 ) {
			$printcfm = processMultipleBOMs( $bomName )

		} elseif( $bomName -match '^(.+CD.+-[12])$' ) {
			$printcfm = $true
		
		} else {
			$printcfm = $false
		}
		
		if( $printcfm ) {
			$forcfm.$bid = @{ bom = $bomName; count = 1 }
		
		} else {
			$nocfm.$bid = @{ bom = $bomName; count = 1 }
		}
		
	} elseif( $null -ne $nocfm.$bid ) {
		$nocfm.$bid.count += 1
	
	} else {
		$forcfm.$bid.count += 1
	}
}
$data = @{ $true = $forcfm; $false = $nocfm }

# Loop through the organized data to officially print the labels.
foreach( $printcfm in  $true, $false ) { 
	foreach( $item in $data.GetEnumerator() | Sort-Object Value -Descending ) {
		$bomName = $data.$printcfm.bom
			

		if( $printcfm ) {
			Write-Output "Sending $bomName to CFM"
			$print = 556, 570
		
		} else {
			Write-Output "Printing labels for $bomName"
			$print = 658, 570
		}
		
		(Get-Content $filterTemplate) -replace 'filler', $bid | Set-Content $filter

		foreach( $step in $steps ) {
			if( $step -match "steps" ) {
				continue
			}

			$arr = $step.split( "," )
			
			$message = $arr[0]
			$x = $arr[1]
			$y = $arr[2]
			$wait = [int]$arr[4]
			
			$leftClick = $true
			if( $arr[3] -match "right" ) {
				$leftClick = $false
			}
			if( $message -eq "print" ) {
				$x = $print[0]
				$y = $print[1]
				
				if( $printcfm ) {
					$wait = 5
				
				} else {
					$wait = 30
				}
			}

			if( $leftClick ) {
				[Clicker]::LeftClickAtPoint( [int]$x, [int]$y )
			
			} else {
				[Clicker]::RightClickAtPoint( [int]$x, [int]$y )
			}
			
			Start-Sleep -s $wait
		}
	}
}




#yes,556,570
#no,658,570

# Add-Type -AssemblyName System.Windows.Forms


# $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen

# $screen | Get-member -MemberType Property

# Write-Host $screen.Width
# [Windows.Forms.Cursor]::Position = "$($screen.Width),$($screen.Height)"
