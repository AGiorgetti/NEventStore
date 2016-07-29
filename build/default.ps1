properties {
    $base_directory = Resolve-Path ..
    $publish_directory = "$base_directory\publish-net40"
    #$build_directory = "$base_directory\build"
    $src_directory = "$base_directory\src"
    $output_directory = "$base_directory\output"
    #$packages_directory = "$src_directory\packages"
    $sln_file = "$src_directory\NEventStore.sln"
    $target_config = "Release"
    #$framework_version = "v4.0"
    #$assemblyInfoFilePath = "$src_directory\AssemblyInfo.cs"

    $xunit_path = "$base_directory\bin\xunit.runners.1.9.1\tools\xunit.console.clr4.exe"
    $ilMergeModule.ilMergePath = "$base_directory\bin\ilmerge-bin\ILMerge.exe"
    
	#$nuget_dir = "$src_directory\.nuget"

    if($runPersistenceTests -eq $null) {
    	$runPersistenceTests = $false
    }
}

task default -depends Build

task Build -depends Clean, UpdateVersion, Compile, Test

task UpdateVersion {
	# a task to invoke GitVersion using the configuration file found in the 
	# root of the repository (GitVersionConfig.yaml)
	& ..\src\packages\GitVersion.CommandLine.3.5.4\tools\GitVersion.exe $base_directory /nofetch /updateassemblyinfo

	# outdated code that was using parameters passed to the build script
	#$version = Get-Version $assemblyInfoFilePath
    #"Version: $version"
	#$oldVersion = New-Object Version $version
	#$newVersion = New-Object Version ($oldVersion.Major, $oldVersion.Minor, $oldVersion.Build, $buildNumber)
	#Update-Version $newVersion $assemblyInfoFilePath
}

task Compile {
	exec { msbuild /nologo /verbosity:quiet $sln_file /p:Configuration=$target_config /t:Clean }
	exec { msbuild /nologo /verbosity:quiet $sln_file /p:Configuration=$target_config /p:TargetFrameworkVersion=v4.0 }
}

task Test -depends RunUnitTests, RunPersistenceTests, RunSerializationTests

task RunUnitTests {
	"Unit Tests"
	EnsureDirectory $output_directory
	Invoke-XUnit -Path $src_directory -TestSpec '*NEventStore.Tests.dll' `
    -SummaryPath $output_directory\unit_tests.xml `
    -XUnitPath $xunit_path
}

task RunPersistenceTests -precondition { $runPersistenceTests } {
	"Persistence Tests"
	EnsureDirectory $output_directory
	Invoke-XUnit -Path $src_directory -TestSpec '*Persistence.MsSql.Tests.dll','*Persistence.MySql.Tests.dll','*Persistence.Oracle.Tests.dll','*Persistence.PostgreSql.Tests.dll','*Persistence.Sqlite.Tests.dll' `
    -SummaryPath $output_directory\persistence_tests.xml `
    -XUnitPath $xunit_path
}

task RunSerializationTests {
	"Serialization Tests"
	EnsureDirectory $output_directory
	Invoke-XUnit -Path $src_directory -TestSpec '*Serialization.*.Tests.dll' `
    -SummaryPath $output_directory\serialization_tests.xml `
    -XUnitPath $xunit_path
}

task Package -depends Build, PackageNEventStore {
	move $output_directory $publish_directory
}

task PackageNEventStore -depends Clean, Compile {
	mkdir "$publish_directory\bin" | out-null
	###Merge-Assemblies -outputFile "$publish_directory/bin/NEventStore.dll" -files @(
	###	"$src_directory/NEventStore/bin/$target_config/NEventStore.dll",
	###	"$src_directory/NEventStore/bin/$target_config/System.Reactive.Interfaces.dll",
	###	"$src_directory/NEventStore/bin/$target_config/System.Reactive.Core.dll",
	###	"$src_directory/NEventStore/bin/$target_config/System.Reactive.Linq.dll",
	###	"$src_directory/NEventStore/bin/$target_config/Newtonsoft.Json.dll"
	###)

    Copy-Item -Path $src_directory/NEventStore/bin/$target_config/NEventStore.dll -Destination "$publish_directory\bin"
	Copy-Item -Path $src_directory/NEventStore.Serialization.Json/bin/$target_config/NEventStore.Serialization.Json.dll -Destination "$publish_directory\bin"
}

task Clean {
	Clean-Item $publish_directory -ea SilentlyContinue
    Clean-Item $output_directory -ea SilentlyContinue
}

# todo: review this action, this is not going to work
#task NuGetPack -depends Package {
#    $versionString = Get-Version $assemblyInfoFilePath
#	$version = New-Object Version $versionString
#	$packageVersion = $version.Major.ToString() + "." + $version.Minor.ToString() + "." + $version.Build.ToString() + "-build" + $build_number.ToString().PadLeft(5,'0')
#	gci -r -i *.nuspec "$nuget_dir" |% { .$nuget_dir\nuget.exe pack $_ -basepath $base_directory -o $publish_directory -version $packageVersion }
#}

function EnsureDirectory {
	param($directory)

	if(!(test-path $directory))
	{
		mkdir $directory
	}
}

# GRD TASKS

function Update-AssemblyInformationalVersion
{
	param
    (
		[string]$version,
		[string]$assemblyInfoFilePath
	)

	$newFileVersion = 'AssemblyInformationalVersion("' + $version + '")';
	$tmpFile = $assemblyInfoFilePath + ".tmp"

	Get-Content $assemblyInfoFilePath |
		%{$_ -replace 'AssemblyInformationalVersion\("[0-9]+(\.([^.]+|\*)){1,4}"\)', $newFileVersion }  | Out-File -Encoding UTF8 $tmpFile

	Move-Item $tmpFile $assemblyInfoFilePath -force
}

task GrdUpdateVersion {
	#$git_version = (& $base_directory\bin\git\git.exe rev-parse HEAD)
	
	$git_version = (& git.exe rev-parse HEAD)
	
	$version = Get-Version $assemblyInfoFilePath
    "Base Version: $version - Git commit: $git_version"
	$oldVersion = New-Object Version $version
	#$newVersion = New-Object Version ($oldVersion.Major, $oldVersion.Minor, $oldVersion.Build, $git_version)
	$newVersion = $oldVersion.Major.ToString() + "." + $oldVersion.Minor.ToString() + "." + $oldVersion.Build.ToString() + "." + $build_number.ToString() + "." + $git_version
    "New Version: $newVersion"
	Update-AssemblyInformationalVersion $newVersion $assemblyInfoFilePath
}

task GrdBuild -depends Clean, UpdateVersion, GrdUpdateVersion, Compile, Test

task GrdPackage -depends GrdBuild, PackageNEventStore {
	move $output_directory $publish_directory
}

# END GRD TASKS