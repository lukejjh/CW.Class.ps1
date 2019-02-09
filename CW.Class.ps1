class CW {
  [string] $BaseURL
  [string] $AuthString
  [string] $Company
  [string] $PublicKey
  [string] $PrivateKey

  CW (
    [string] $BaseURL,
    [string] $Company,
    [string] $PublicKey,
    [string] $PrivateKey
  ) {
    $this.BaseURL = $BaseURL
    $AuthStringUnencoded = ("{0}+{1}:{2}" -f $Company, $PublicKey, $PrivateKey)
    Write-Debug ("Using unencoded auth string: {0}" -f $AuthStringUnencoded)
    $this.AuthString = ([Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($AuthStringUnencoded)))
  }

  [object]Request (
    [string] $Slug,
    [object] $Method,
    [object] $Body
  ) {
    
    $MAX_PAGE_SIZE = 1000
    
    $Uri = ("{0}/{1}" -f $this.BaseURL, $Slug)
    $Headers = @{
      "Authorization"   = ("Basic {0}" -f $this.AuthString)
      "Content-Type"    = "application/json"
      "Pagination-Type" = "Forward-Only"
    }

    $PageSizeSet = $Body.pageSize -ne $null
    $RequestResultSum = @()

    if ($Method.toLower() -eq "get" -and !$PageSizeSet) {
      $Body.pageSize = $MAX_PAGE_SIZE
    }
    if (("post", "patch", "put") -contains $Method.toLower()) {
      $Body = ConvertTo-Json $Body
    }
    $RequestResult = Invoke-WebRequest -Uri $Uri -Headers $Headers -Method $Method -Body $Body
    $RequestResultSum += ConvertFrom-Json $RequestResult.Content
    if (!$PageSizeSet) {
      while ($RequestResult.Headers["Link"]) {
        $Uri = $RequestResult.Headers["Link"].Split("; ")[0] -replace "[\^<,>$]",""
        $RequestResult = Invoke-WebRequest -Uri $Uri -Headers $Headers -Method $Method
        $RequestResultSum += ConvertFrom-Json $RequestResult.Content
      }
    }
    return $RequestResultSum
  }
}