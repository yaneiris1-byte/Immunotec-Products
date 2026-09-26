param(
  [Parameter(Mandatory = $true)]
  [string]$SiteUrl,
  [string]$OutputPath = $PSScriptRoot
)

$siteUri = $null
if (-not [uri]::TryCreate($SiteUrl, [System.UriKind]::Absolute, [ref]$siteUri)) {
  throw "SiteUrl must be an absolute public URL, such as https://example.com."
}
if ($siteUri.Scheme -notin @('http', 'https') -or $siteUri.Query -or $siteUri.Fragment) {
  throw "SiteUrl must use HTTP or HTTPS and cannot include a query or fragment."
}

$siteRoot = $siteUri.AbsoluteUri.TrimEnd('/') + '/'
$spanishUrl = [uri]::new([uri]$siteRoot, 'index.html').AbsoluteUri
$englishUrl = [uri]::new([uri]$siteRoot, 'index-en.html').AbsoluteUri
$sitemapUrl = [uri]::new([uri]$siteRoot, 'sitemap.xml').AbsoluteUri
$outputDirectory = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path -LiteralPath $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$sitemap = New-Object System.Xml.XmlDocument
$declaration = $sitemap.CreateXmlDeclaration('1.0', 'UTF-8', $null)
$sitemap.AppendChild($declaration) | Out-Null
$urlset = $sitemap.CreateElement('urlset', 'http://www.sitemaps.org/schemas/sitemap/0.9')
$urlset.SetAttribute('xmlns:xhtml', 'http://www.w3.org/1999/xhtml')
$sitemap.AppendChild($urlset) | Out-Null

foreach ($pageUrl in @($spanishUrl, $englishUrl)) {
  $url = $sitemap.CreateElement('url', 'http://www.sitemaps.org/schemas/sitemap/0.9')
  $loc = $sitemap.CreateElement('loc', 'http://www.sitemaps.org/schemas/sitemap/0.9')
  $loc.InnerText = $pageUrl
  $url.AppendChild($loc) | Out-Null

  foreach ($alternate in @(
    @{ Language = 'es'; Url = $spanishUrl },
    @{ Language = 'en'; Url = $englishUrl },
    @{ Language = 'x-default'; Url = $spanishUrl }
  )) {
    $link = $sitemap.CreateElement('xhtml', 'link', 'http://www.w3.org/1999/xhtml')
    $link.SetAttribute('rel', 'alternate')
    $link.SetAttribute('hreflang', $alternate.Language)
    $link.SetAttribute('href', $alternate.Url)
    $url.AppendChild($link) | Out-Null
  }

  $urlset.AppendChild($url) | Out-Null
}

$sitemapPath = Join-Path $outputDirectory 'sitemap.xml'
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$writer = [System.Xml.XmlWriter]::Create($sitemapPath, $settings)
try {
  $sitemap.Save($writer)
} finally {
  $writer.Dispose()
}

$robotsPath = Join-Path $outputDirectory 'robots.txt'
@(
  'User-agent: *',
  'Allow: /',
  "Sitemap: $sitemapUrl"
) | Set-Content -LiteralPath $robotsPath -Encoding Ascii

Write-Host "Updated sitemap.xml and robots.txt in $outputDirectory"
Write-Host "Submit $sitemapUrl in Google Search Console to request discovery."