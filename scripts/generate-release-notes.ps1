param(
  [Parameter(Mandatory = $true)]
  [string]$Tag,

  [Parameter(Mandatory = $true)]
  [string]$Repository,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$tagCommit = (& git rev-list -n 1 $Tag).Trim()
if ($LASTEXITCODE -ne 0 -or !$tagCommit) {
  throw "Could not resolve tag '$Tag'."
}

$previousTag = & git tag --merged "$Tag^" --list "v[0-9]*" --sort=-v:refname |
  Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
  throw "Could not find the tag preceding '$Tag'."
}

$range = if ($previousTag) { "$previousTag..$Tag" } else { $Tag }
$commits = @(& git log $range --reverse --no-merges --format="%H%x09%s")
if ($LASTEXITCODE -ne 0) {
  throw "Could not read commits for '$range'."
}

$sections = [ordered]@{
  "Breaking changes" = @()
  "Features" = @()
  "Fixes" = @()
  "Performance" = @()
  "Documentation" = @()
  "Build" = @()
  "Continuous integration" = @()
  "Refactoring" = @()
  "Tests" = @()
  "Maintenance" = @()
  "Initial release" = @()
  "Other changes" = @()
}

foreach ($commit in $commits) {
  if (!$commit) { continue }

  $parts = $commit -split "`t", 2
  $hash = $parts[0]
  $subject = if ($parts.Length -eq 2) { $parts[1] } else { $hash }
  $shortHash = $hash.Substring(0, 7)
  $body = (& git show -s --format="%b" $hash) -join "`n"
  if ($LASTEXITCODE -ne 0) { throw "Could not read commit '$hash'." }

  $type = ""
  $scope = ""
  $description = $subject
  $breaking = $body -match "(?m)^BREAKING CHANGE:\s*"

  if ($subject -match "^(?<type>[A-Za-z]+)(?:\((?<scope>[^)]+)\))?(?<breaking>!)?:\s+(?<description>.+)$") {
    $type = $Matches.type.ToLowerInvariant()
    $scope = if ($Matches.ContainsKey("scope")) { $Matches.scope } else { "" }
    $description = $Matches.description
    $breaking = $breaking -or ($Matches.ContainsKey("breaking") -and [bool]$Matches.breaking)
  }

  $category = if ($breaking) {
    "Breaking changes"
  } else {
    switch ($type) {
      "feat" { "Features" }
      "fix" { "Fixes" }
      "perf" { "Performance" }
      "docs" { "Documentation" }
      "build" { "Build" }
      "ci" { "Continuous integration" }
      "refactor" { "Refactoring" }
      "test" { "Tests" }
      "chore" { "Maintenance" }
      "init" { "Initial release" }
      default { "Other changes" }
    }
  }

  $entry = "- "
  if ($scope) { $entry += "**${scope}:** " }
  $entry += "$description [$shortHash](https://github.com/$Repository/commit/$hash)"
  $sections[$category] += $entry
}

$notes = [System.Collections.Generic.List[string]]::new()
foreach ($section in $sections.GetEnumerator()) {
  if ($section.Value.Count -eq 0) { continue }
  $notes.Add("## $($section.Key)")
  $notes.Add("")
  foreach ($entry in $section.Value) { $notes.Add($entry) }
  $notes.Add("")
}

if ($notes.Count -eq 0) {
  $notes.Add("No commits were found for this release.")
  $notes.Add("")
}

if ($previousTag) {
  $notes.Add("**Full changelog:** [$previousTag...$Tag](https://github.com/$Repository/compare/$previousTag...$Tag)")
} else {
  $notes.Add("**Commit history:** [$Tag](https://github.com/$Repository/commits/$Tag)")
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
$notes | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Generated release notes for $Tag from $($commits.Count) commit(s)."
if ($previousTag) { Write-Host "Previous tag: $previousTag" }
