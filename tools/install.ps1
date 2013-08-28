param($installPath, $toolsPath, $package, $project)

function InjectTargets($installPath, $project, $targetsFilePath)
{
	$targetsFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($project.FullName), $targetsFilePath)

	# Grab the loaded MSBuild project for the project
	$buildProject = @([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($project.FullName))[0]

	$importsToRemove = $buildProject.Xml.Imports | Where-Object { $_.Project.Endswith($targetsFilePath) }

	# remove existing imports
	foreach ($importToRemove in $importsToRemove) 
	{ 
		if ($importToRemove)
		{
			$buildProject.Xml.RemoveChild($importToRemove) | out-null
		}
	}

	# Make the path to the targets file relative.
	$projectUri = new-object Uri('file://' + $project.FullName)
	$targetUri = new-object Uri('file://' + $targetsFile)
	$installUri = new-object Uri('file://' + $installPath)
	$relativePath = $projectUri.MakeRelativeUri($targetUri).ToString().Replace([System.IO.Path]::AltDirectorySeparatorChar, [System.IO.Path]::DirectorySeparatorChar)

	# Add the import
	$importElement = $buildProject.Xml.AddImport($relativePath)
}

function ChangeTypeScriptBuildAction($installPath, $project)
{
    $buildProject = @([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($project.FullName))[0]
    $typeScriptItems = $buildProject.Xml.ItemGroups.Children | where { $_.ItemType -ne "TypeScriptCompile" -and $_.Include.ToLower().EndsWith(".ts") -and -not $_.Include.ToLower().EndsWith(".d.ts") }
    $typeScriptItems | % { $_.ItemType = "TypeScriptCompile" }
    $typeScriptItems
}

$targetsFilePath = 'Build\TypeScriptConfiguration.targets'

Write-Host '- Adding <Import /> into project file...'
InjectTargets $installPath $project $targetsFilePath
InjectTargets $installPath $project '$(MSBuildExtensionsPath32)\Microsoft\VisualStudio\v$(VisualStudioVersion)\TypeScript\Microsoft.TypeScript.targets'
Write-Host '- Targets imported.'

Write-Host '- Change BuildAction of .ts to TypeScriptCompile (exclude .d.ts)'
$changedItems = ChangeTypeScriptBuildAction $installPath $project
Write-Host "- $($changedItems.Count) .ts items' BuildAction have been changed to [TypeScriptComile]"
Write-Host '- BuildAction changed.'

$project.Save()

$targetsFileFullPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($project.FullName), $targetsFilePath)
$DTE.ItemOperations.OpenFile($targetsFileFullPath)
