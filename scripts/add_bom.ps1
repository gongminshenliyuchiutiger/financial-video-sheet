param([string]$targetFile)
$full = Resolve-Path $targetFile
$bytes = [System.IO.File]::ReadAllBytes($full)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Output "$targetFile already has UTF-8 BOM."
} else {
    $bom = [byte[]]@(0xEF, 0xBB, 0xBF)
    $newBytes = New-Object byte[] ($bom.Length + $bytes.Length)
    [System.Buffer]::BlockCopy($bom, 0, $newBytes, 0, $bom.Length)
    [System.Buffer]::BlockCopy($bytes, 0, $newBytes, $bom.Length, $bytes.Length)
    [System.IO.File]::WriteAllBytes($full, $newBytes)
    Write-Output "Added UTF-8 BOM to $targetFile."
}
