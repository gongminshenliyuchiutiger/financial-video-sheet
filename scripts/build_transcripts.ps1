[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$rootDir = Split-Path $PSScriptRoot -Parent
$transcriptDir = Join-Path $rootDir "金融基礎教育主題教材教學影片逐字稿"
$txtFiles = Get-ChildItem -Path $transcriptDir -Filter "*.txt"

Write-Output "Found $($txtFiles.Count) transcript files."

foreach ($txtFile in $txtFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($txtFile.Name)
    $htmlPath = Join-Path $rootDir "$baseName.html"
    
    if (-not (Test-Path $htmlPath)) {
        Write-Warning "HTML file not found: $htmlPath"
        continue
    }
    
    Write-Output "Processing: $baseName ..."
    $rawText = [System.IO.File]::ReadAllText($txtFile.FullName, [System.Text.Encoding]::UTF8)
    
    # Extract timestamps
    $regex = [regex]::new('(?m)^\*\*(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})\*\*')
    $allMatches = $regex.Matches($rawText)
    
    if ($allMatches.Count -eq 0) {
        Write-Warning "No timestamps found in $($txtFile.Name)"
        continue
    }
    
    $dialogueItems = @()
    for ($i = 0; $i -lt $allMatches.Count; $i++) {
        $m = $allMatches[$i]
        $timeStr = $m.Groups[1].Value.Trim()
        $startPos = $m.Index + $m.Length
        $endPos = if ($i -lt $allMatches.Count - 1) { $allMatches[$i+1].Index } else { $rawText.Length }
        
        $chunk = $rawText.Substring($startPos, $endPos - $startPos).Trim()
        $lines = $chunk -split "`r?`n" | Where-Object { $_.Trim() -ne '' }
        
        $linesHtml = ""
        foreach ($line in $lines) {
            $t = $line.Trim()
            if ($t -match '^\*\[(.+)\]\*$') {
                $act = $Matches[1].Trim()
                $linesHtml += "              <p class=`"dialogue-action`"><i class=`"fa-solid fa-clapperboard`"></i> [$act]</p>`n"
            }
            elseif ($t -match '^\*\*([^*]+)\*\*[：:]\s*(.*)$') {
                $speaker = $Matches[1].Trim()
                $speech = $Matches[2].Trim()
                $speech = [regex]::Replace($speech, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
                $linesHtml += "              <p class=`"dialogue-line`"><span class=`"dialogue-speaker`">$speaker</span>：$speech</p>`n"
            }
            else {
                $tClean = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
                $linesHtml += "              <p class=`"dialogue-line`">$tClean</p>`n"
            }
        }
        
        $dialogueItems += @"
            <div class="transcript-dialogue-item">
              <div class="dialogue-meta">
                <span class="dialogue-timestamp"><i class="fa-regular fa-clock"></i> $timeStr</span>
              </div>
              <div class="dialogue-body">
$linesHtml              </div>
            </div>
"@
    }
    
    $allDialoguesHtml = $dialogueItems -join "`n"
    $dialogueCount = $dialogueItems.Count
    
    # Read HTML content
    $htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
    
    # 1. Update Word download button in action-bar-right if not present
    $wordBtnHtml = @"
        <a href="docx/$($baseName)_學習單.docx" download class="btn-action btn-action-word" title="下載可編輯/列印的 Word 檔學習單 (.docx)">
          <i class="fa-solid fa-file-word"></i> 下載 Word 檔
        </a>
"@
    if ($htmlContent -notmatch 'btn-action-word') {
        $htmlContent = $htmlContent -replace '(<div class="action-bar-right">\s*)', "`$1$wordBtnHtml`n"
    }
    
    # 2. Update toggle title to indicate full count
    $toggleRegex = [regex]::new('<div class="transcript-summary-toggle">[\s\S]*?<span>[\s\S]*?</span>')
    $newToggle = @"
<div class="transcript-summary-toggle">
          <span><i class="fa-solid fa-file-lines"></i> 點擊展開 / 收合完整逐字稿對照（共收錄 $dialogueCount 幕完整影音台詞）</span>
"@
    if ($toggleRegex.IsMatch($htmlContent)) {
        $htmlContent = $toggleRegex.Replace($htmlContent, $newToggle, 1)
    }
    
    # 3. Replace transcript-text-viewer content
    $viewerRegex = [regex]::new('(<div class="transcript-text-viewer">)[\s\S]*?(</div>\s*</div>\s*</div>\s*<!-- Task 1)')
    $replacement = "`$1`n$allDialoguesHtml`n          `$2"
    if ($viewerRegex.IsMatch($htmlContent)) {
        $htmlContent = $viewerRegex.Replace($htmlContent, $replacement, 1)
        [System.IO.File]::WriteAllText($htmlPath, $htmlContent, [System.Text.Encoding]::UTF8)
        Write-Output "Successfully updated transcript in $baseName.html ($dialogueCount items)."
    } else {
        Write-Warning "Could not match transcript-text-viewer regex in $baseName.html"
    }
}

Write-Output "Transcript build process completed."
