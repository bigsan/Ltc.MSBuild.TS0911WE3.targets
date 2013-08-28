param($installPath, $toolsPath, $package, $project)

function RemoveTargets($installPath, $project, $targetsFilePath)
{
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
}

$targetsFilePath = 'Build\TypeScriptConfiguration.targets'

Write-Host '- Removing <Import /> from project file...'
RemoveTargets $installPath $project $targetsFilePath
RemoveTargets $installPath $project 'TypeScript\Microsoft.TypeScript.targets'
Write-Host '- Targets removed.'

$project.Save()
