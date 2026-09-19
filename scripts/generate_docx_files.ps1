[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Escape-Xml([string]$str) {
    if ([string]::IsNullOrEmpty($str)) { return "" }
    return $str.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

function New-DocxArchive([string]$targetPath, [string]$bodyXml) {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("docx_" + [System.Guid]::NewGuid().ToString())
    $wordDir = Join-Path $tempDir "word"
    $relsDir = Join-Path $tempDir "_rels"
    
    New-Item -ItemType Directory -Path $wordDir -Force | Out-Null
    New-Item -ItemType Directory -Path $relsDir -Force | Out-Null
    
    $contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
'@
    [System.IO.File]::WriteAllText((Join-Path $tempDir "[Content_Types].xml"), $contentTypes, [System.Text.Encoding]::UTF8)
    
    $rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@
    [System.IO.File]::WriteAllText((Join-Path $relsDir ".rels"), $rels, [System.Text.Encoding]::UTF8)
    
    $docXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $bodyXml
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>
"@
    [System.IO.File]::WriteAllText((Join-Path $wordDir "document.xml"), $docXml, [System.Text.Encoding]::UTF8)
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path $targetPath) { Remove-Item $targetPath -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $targetPath)
    Remove-Item -Recurse -Force $tempDir
}

# XML Generator Helpers
function Xml-P([string]$text, [string]$color="1E293B", [int]$sz=22, [bool]$bold=$false, [string]$align="left", [int]$before=60, [int]$after=60) {
    $bTag = if ($bold) { "<w:b/>" } else { "" }
    $safe = Escape-Xml $text
    return @"
<w:p>
  <w:pPr>
    <w:jc w:val="$align"/>
    <w:spacing w:before="$before" w:after="$after"/>
  </w:pPr>
  <w:r>
    <w:rPr>$bTag<w:color w:val="$color"/><w:sz w:val="$sz"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr>
    <w:t>$safe</w:t>
  </w:r>
</w:p>
"@
}

function Xml-Heading1([string]$title, [string]$subtitle) {
    $sTitle = Escape-Xml $title
    $sSub = Escape-Xml $subtitle
    return @"
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:pBdr><w:bottom w:val="double" w:sz="18" w:space="8" w:color="1E3A8A"/></w:pBdr>
    <w:spacing w:before="120" w:after="100"/>
  </w:pPr>
  <w:r>
    <w:rPr><w:b/><w:color w:val="1E3A8A"/><w:sz w:val="36"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr>
    <w:t>$sTitle</w:t>
  </w:r>
</w:p>
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="60" w:after="240"/>
  </w:pPr>
  <w:r>
    <w:rPr><w:color w:val="0D9488"/><w:b/><w:sz w:val="22"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr>
    <w:t>$sSub</w:t>
  </w:r>
</w:p>
"@
}

function Xml-SectionTitle([string]$title, [string]$color="1E3A8A") {
    $s = Escape-Xml $title
    return @"
<w:p>
  <w:pPr>
    <w:shd w:val="clear" w:color="auto" w:fill="F1F5F9"/>
    <w:pBdr><w:left w:val="single" w:sz="24" w:space="8" w:color="$color"/></w:pBdr>
    <w:spacing w:before="240" w:after="120"/>
  </w:pPr>
  <w:r>
    <w:rPr><w:b/><w:color w:val="$color"/><w:sz w:val="26"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr>
    <w:t>  $s</w:t>
  </w:r>
</w:p>
"@
}

function Xml-StudentInfoTable() {
    return @'
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="9200" w:type="dxa"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:left w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="1600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>學校名稱</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t></w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="1600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>班級／座號</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t></w:t></w:r></w:p></w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="1600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>學生姓名</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t></w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="1600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>完成日期</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t></w:t></w:r></w:p></w:tc>
  </w:tr>
</w:tbl>
<w:p><w:spacing w:before="120"/></w:p>
'@
}

function Xml-AnswerBox([string]$prompt, [int]$linesCount=4) {
    $sPrompt = Escape-Xml $prompt
    $blankRows = ""
    for ($i = 0; $i -lt $linesCount; $i++) {
        $blankRows += '<w:p><w:pPr><w:spacing w:before="60" w:after="60"/></w:pPr><w:r><w:rPr><w:color w:val="94A3B8"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>_________________________________________________________________________________</w:t></w:r></w:p>'
    }
    return @"
<w:p>
  <w:pPr><w:spacing w:before="80" w:after="60"/></w:pPr>
  <w:r><w:rPr><w:b/><w:color w:val="475569"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>【作答與思辨分析區】（$sPrompt）：</w:t></w:r>
</w:p>
$blankRows
"@
}

function Xml-GroupActivity([string]$actTitle, [string]$roleA, [string]$roleB, [string]$guidance) {
    $sTitle = Escape-Xml $actTitle
    $sRoleA = Escape-Xml $roleA
    $sRoleB = Escape-Xml $roleB
    $sGuidance = Escape-Xml $guidance
    return @"
<w:p>
  <w:pPr><w:spacing w:before="120" w:after="80"/></w:pPr>
  <w:r><w:rPr><w:b/><w:color w:val="6B21A8"/><w:sz w:val="24"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>★ 小組合作任務：$sTitle</w:t></w:r>
</w:p>
<w:p>
  <w:pPr><w:spacing w:before="40" w:after="100"/></w:pPr>
  <w:r><w:rPr><w:color w:val="475569"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>討論引導：$sGuidance</w:t></w:r>
</w:p>
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="9200" w:type="dxa"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="6" w:space="0" w:color="D8B4FE"/>
      <w:left w:val="single" w:sz="6" w:space="0" w:color="D8B4FE"/>
      <w:bottom w:val="single" w:sz="6" w:space="0" w:color="D8B4FE"/>
      <w:right w:val="single" w:sz="6" w:space="0" w:color="D8B4FE"/>
      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E9D5FF"/>
      <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E9D5FF"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="4600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="FAF5FF"/></w:tcPr>
      <w:p><w:pPr><w:spacing w:before="60" w:after="40"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="6B21A8"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>組員 A 立場／角色：$sRoleA</w:t></w:r></w:p>
      <w:p><w:r><w:rPr><w:color w:val="64748B"/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>觀點記錄：</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_____________________________________________</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_____________________________________________</w:t></w:r></w:p>
    </w:tc>
    <w:tc><w:tcPr><w:tcW w:w="4600" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="FAF5FF"/></w:tcPr>
      <w:p><w:pPr><w:spacing w:before="60" w:after="40"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="6B21A8"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>組員 B 立場／角色：$sRoleB</w:t></w:r></w:p>
      <w:p><w:r><w:rPr><w:color w:val="64748B"/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>觀點記錄：</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_____________________________________________</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_____________________________________________</w:t></w:r></w:p>
    </w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:tcPr><w:gridSpan w:val="2"/><w:tcW w:w="9200" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="FFFFFF"/></w:tcPr>
      <w:p><w:pPr><w:spacing w:before="80" w:after="40"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="1E3A8A"/><w:sz w:val="20"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>【小組共識與綜合策略結論】：</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_________________________________________________________________________________</w:t></w:r></w:p>
      <w:p><w:spacing w:before="60" w:after="60"/><w:r><w:rPr><w:color w:val="CBD5E1"/><w:sz w:val="18"/></w:rPr><w:t>_________________________________________________________________________________</w:t></w:r></w:p>
    </w:tc>
  </w:tr>
</w:tbl>
<w:p><w:spacing w:before="120"/></w:p>
"@
}

function Xml-SelfEval() {
    return @'
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="9200" w:type="dxa"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:left w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>
      <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="6000" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>學習評量項目</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3200" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/></w:tcPr><w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>自我評核（勾選）</w:t></w:r></w:p></w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="6000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>1. 我能完全理解影片所闡述的金融核心法規與觀念</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3200" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>□ 非常清楚  □ 大致理解  □ 需再複習</w:t></w:r></w:p></w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="6000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>2. 我能在小組討論中清晰陳述個人觀點並與同儕達成共識</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3200" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>□ 積極互動  □ 良好配合  □ 尚可加強</w:t></w:r></w:p></w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:tcPr><w:tcW w:w="6000" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>3. 我能將本課學到的金融素養運用在日常生活金錢決策中</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:tcW w:w="3200" w:type="dxa"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="18"/><w:rFonts w:ascii="Microsoft JhengHei" w:eastAsia="Microsoft JhengHei"/></w:rPr><w:t>□ 完全有信心  □ 願意嘗試  □ 尋求協助</w:t></w:r></w:p></w:tc>
  </w:tr>
</w:tbl>
<w:p><w:spacing w:before="120"/></w:p>
'@
}

Write-Output "Docx generator engine ready."
