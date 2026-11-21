$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "IAC CHECK FAILED: $Message"
}

$terraformVersion = terraform version
if ($LASTEXITCODE -ne 0) {
    Fail "Terraform is not available in PATH."
}
$terraformVersionText = ($terraformVersion | Select-Object -First 1).ToString()
Write-Host "Detected $terraformVersionText"

terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Fail "terraform fmt -check -recursive reported formatting differences."
}

terraform init -backend=false -input=false
if ($LASTEXITCODE -ne 0) {
    Fail "terraform init failed."
}

terraform validate -no-color
if ($LASTEXITCODE -ne 0) {
    Fail "terraform validate failed."
}

$requiredVars = @(
    "project",
    "environment",
    "owner",
    "cost_center",
    "managed_by",
    "data_classification"
)

foreach ($path in @("main.tf", "variables.tf", "providers.tf")) {
    if (-not (Test-Path $path)) {
        Fail "Required Terraform file is missing: $path"
    }
}

$terraformText = Get-Content -Path @("main.tf", "variables.tf") -Raw
foreach ($tag in $requiredVars) {
    if ($tag -ne "project" -and $tag -ne "managed_by") {
        if ($terraformText -notmatch [regex]::Escape($tag)) {
            Fail "Required governance tag '$tag' is not declared."
        }
    }
    elseif ($terraformText -notmatch [regex]::Escape($tag)) {
        Fail "Required governance tag '$tag' is not declared."
    }
}

if ($terraformText -notmatch "https_traffic_only_enabled\s*=\s*true") {
    Fail "Storage account must require HTTPS."
}
if ($terraformText -notmatch "allow_nested_items_to_be_public\s*=\s*false") {
    Fail "Public blob/container access must be disabled."
}
if ($terraformText -notmatch "enable_rbac_authorization\s*=\s*true") {
    Fail "Key Vault must use Azure RBAC authorization."
}
if ($terraformText -notmatch "local_authentication_disabled\s*=\s*true") {
    Fail "Cosmos DB local authentication must be disabled."
}
if ($terraformText -notmatch 'enable_cosmos_free_tier') {
    Fail "Cosmos DB free tier must be configurable."
}

if (Get-Command trivy -ErrorAction SilentlyContinue) {
    trivy config --severity HIGH,CRITICAL --exit-code 1 .
    if ($LASTEXITCODE -ne 0) {
        Fail "Trivy found HIGH or CRITICAL IaC misconfigurations."
    }
}
else {
    Write-Warning "Trivy is not installed; skipping trivy config."
}

Write-Host "IaC governance checks passed."
