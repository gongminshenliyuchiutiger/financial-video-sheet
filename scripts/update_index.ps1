[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$indexPath = Join-Path (Split-Path $PSScriptRoot -Parent) "index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# 1. Update Hero Description
$oldDesc = "將 9 部國小、國中、高中生動有趣的金融教育逐字稿轉化為線上互動學習單。支援隨堂測驗、情境思辨、觸控手繪作答與一鍵匯出 PDF/PNG，全面深化學生的金錢素養！"
$newDesc = "將 9 部國小、國中、高中生動有趣的金融教育完整逐字稿轉化為線上互動學習單。全面收錄完整對話、支援即時搜尋、延伸金融素養與分組深入討論，並提供 Word (.docx) / PDF / PNG 多格式下載！"
$content = $content.Replace($oldDesc, $newDesc)

# 2. Update stats bar 3rd item if needed
$oldStat = '<div class="stat-number">100%</div>' + "`r`n" + '            <div class="stat-label">支援手繪與匯出</div>'
# We can keep stat or refine it
$content = $content -replace '100%</div>\s*<div class="stat-label">支援手繪與匯出', 'Word / PDF</div>`n            <div class="stat-label">支援手繪與多格式下載'

# 3. Add Word download link in each card footer if not already added
$pattern = '(?s)<a href="([^"]+\.html)" class="btn-open-sheet">\s*<i class="fa-solid fa-file-pen"></i> 進入互動學習單\s*</a>\s*(?!<a href="docx/)'

$evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
    param($match)
    $htmlFile = $match.Groups[1].Value
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($htmlFile)
    return @"
<a href="$htmlFile" class="btn-open-sheet">
              <i class="fa-solid fa-file-pen"></i> 進入互動學習單
            </a>
            <a href="docx/$($baseName)_學習單.docx" download class="btn-card-word" title="下載 Word 檔學習單 (.docx)">
              <i class="fa-solid fa-file-word"></i> Word 檔
            </a>
"@
}

$content = [regex]::Replace($content, $pattern, $evaluator)

[System.IO.File]::WriteAllText($indexPath, $content, [System.Text.Encoding]::UTF8)
Write-Output "Successfully updated index.html with Word download buttons."
