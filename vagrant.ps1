function Renew-Vagrant-Box {
	$VagrantBoxDestroy = $( Start-Process -FilePath "vagrant.exe" -ArgumentList "destroy", "--force" -NoNewWindow -Wait );
	if( $VagrantBoxDestroy ){
		Write-Output $VagrantBoxDestroy;
		$vup = $( Start-Process -FilePath "vagrant.exe" -ArgumentList "up" );
		if($vup){
			Write-Output $vup;
		}
	}
}

# Uses -NoNewWindow and -Wait
# Uses an array and slices it. untested, unknown
function DoProcessWait {
	Param(
		[Parameter(Mandatory=$true)]
		[string[]]$Args
	)
	
	$ouput = Start-Process -FilePath $Args[0] -ArgumentList $Args[1..$Args.length] -NoNewWindow -Wait;
	
	if($output){
		Write-Output $output;
	}
}

function RVB {
	DoProcessWait -Args "vagrant","destroy","--force";
	DoProcessWait -Args "vagrant","up","--provision";
	DoProcessWait -Args "vagrant","ssh";
}

RVB;

