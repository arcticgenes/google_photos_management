
# Replace <CLIENT_ID_HERE> with your client id
#https://accounts.google.com/o/oauth2/auth?redirect_uri=<CLIENT_ID_HERE>&scope=https://www.googleapis.com/auth/photoslibrary.readonly&approval_prompt=force&access_type=offline

$clientId = ""
$clientSecret = ""

$scopes = "https://www.googleapis.com/auth/photoslibrary.readonly"


Start-Process "https://accounts.google.com/o/oauth2/v2/auth?client_id=$clientId&scope=$([string]::Join("%20", $scopes))&access_type=offline&response_type=code&redirect_uri=urn:ietf:wg:oauth:2.0:oob"    
 
$code = Read-Host "Please enter the code"

$requestUri = "https://www.googleapis.com/oauth2/v4/token"
$redirectURI = "urn:ietf:wg:oauth:2.0:oob";

$body = @{
  code=$code;
  client_id=$clientId;
  client_secret=$clientSecret;
  redirect_uri=$redirectURI;
  grant_type='authorization_code'
}

$tokens = Invoke-RestMethod -Uri $requestUri -Method POST -Body $body


# Store refreshToken
Set-Content .\refreshToken.txt $tokens.refresh_token

# Store accessToken
Set-Content .\accessToken.txt $tokens.access_token


# Save this
$refreshToken = $tokens.refresh_token

$refreshTokenParams = @{
  uri="https://www.googleapis.com/oauth2/v4/token"
  body = @{
    client_id=$clientId;
    client_secret=$clientSecret;
    refresh_token=$tokens.refresh_token
    grant_type="refresh_token"; # Fixed value
  }
  method = 'POST'
}

$tokens = Invoke-RestMethod @refreshTokenParams
  
$tokens = Invoke-RestMethod -Uri $requestUri -Method POST -Body $refreshTokenParams

$secureToken = $tokens.access_token | ConvertTo-SecureString -AsPlainText -Force

$requestParams = @{
  Authentication = 'Bearer'
  Token = $secureToken
  uri = "https://photoslibrary.googleapis.com/v1/albums"
  method = 'GET'
  contentType = 'application/json'
}
  
$photoQuery = Invoke-RestMethod @requestParams


$albumParams = @{
  Authentication = 'Bearer'
  Token = $secureToken
  uri = "https://photoslibrary.googleapis.com/v1/mediaItems:search"
  method = 'POST'
  contentType = 'application/json'
  body = @{

  }
}

$albumQuery = Invoke-RestMethod @albumParams

Invoke-WebRequest -Uri $albumQuery.mediaItems[0].baseUrl -OutFile .\"$($albumQuery.mediaItems[0].fileName)"


