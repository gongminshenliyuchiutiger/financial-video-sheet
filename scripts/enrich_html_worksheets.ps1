[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$rootDir = Split-Path $PSScriptRoot -Parent

. (Join-Path $PSScriptRoot "generate_all_docx.ps1")

# Helper to generate quiz HTML
function Build-QuizHtml($quizList) {
    $html = ""
    $qIdx = 1
    foreach ($q in $quizList) {
        $name = "q$qIdx"
        $optionsHtml = ""
        $letters = @("A", "B", "C", "D")
        for ($i = 0; $i -lt $q.Options.Count; $i++) {
            $optText = $q.Options[$i]
            $val = $letters[$i]
            $optionsHtml += @"
              <label class="option-label">
                <input type="radio" name="$name" value="$val">
                <span>$optText</span>
              </label>`n
"@
        }
        
        $exp = "正解為 $($q.Ans)。"
        $html += @"
          <!-- Q$qIdx -->
          <div class="question-block" data-correct="$($q.Ans.Trim('()'))" data-explanation="$exp">
            <h3 class="question-title">
              <span class="q-number">$qIdx</span>
              $($q.Q)
            </h3>
            <div class="options-group">
$optionsHtml            </div>
            <button type="button" class="btn-check-answer"><i class="fa-solid fa-spell-check"></i> 核對答案</button>
            <div class="explanation-box"></div>
          </div>`n
"@
        $qIdx++
    }
    return $html
}

# Helper to generate discussions HTML
function Build-DiscussionsHtml($discList, $prefix) {
    $html = ""
    $dIdx = 1
    foreach ($d in $discList) {
        $id = "${prefix}_disc_$dIdx"
        $html += @"
          <div class="question-block">
            <h3 class="question-title">
              <span class="q-number" style="background:#d97706;">$dIdx</span>
              $($d.Title)
            </h3>
            <p style="font-size: 0.95rem; color: #4b5563; margin-bottom: 12px; line-height: 1.65;">
              $($d.Prompt)
            </p>
            <div class="reflection-box">
              <textarea id="$id" class="reflection-textarea" placeholder="請在此輸入你的深度分析、策略思考與評估理由..."></textarea>
            </div>
          </div>`n
"@
        $dIdx++
    }
    return $html
}

# Helper to generate group activity HTML
function Build-GroupActivityHtml($act, $prefix) {
    $idA = "${prefix}_role_a"
    $idB = "${prefix}_role_b"
    $idCon = "${prefix}_consensus"
    return @"
      <!-- Task 3: 小組合作與情境角色扮演 -->
      <section class="section-card">
        <div class="section-header" style="background: #faf5ff;">
          <h2 class="section-title" style="color: #6b21a8;"><i class="fa-solid fa-users-viewfinder"></i> 第三部分：小組互動合作與情境角色扮演／思維辯論</h2>
          <span style="font-size: 0.85rem; color: #7e22ce; font-weight: 700;">兩人或四人一組互動演練</span>
        </div>
        <div class="section-body">
          <div class="group-activity-card">
            <div class="group-activity-header">
              <div class="group-activity-title">
                <i class="fa-solid fa-masks-theater"></i> $($act.Title)
              </div>
              <span class="group-role-badge"><i class="fa-solid fa-handshake"></i> 同儕雙向互動研討</span>
            </div>
            <p style="font-size: 0.925rem; color: #4b5563; line-height: 1.6; margin-bottom: 14px;">
              <strong>【討論引導任務】：</strong>$($act.Guidance)
            </p>
            <div class="activity-grid">
              <div class="activity-column">
                <h5><i class="fa-solid fa-user"></i> $($act.RoleA)</h5>
                <textarea id="$idA" class="activity-textarea" placeholder="請組員 A 記錄個人立場之核心論點、考量理由與支持依據..."></textarea>
              </div>
              <div class="activity-column">
                <h5><i class="fa-solid fa-user-group"></i> $($act.RoleB)</h5>
                <textarea id="$idB" class="activity-textarea" placeholder="請組員 B 記錄個人立場之核心論點、考量理由與支持依據..."></textarea>
              </div>
            </div>
            <div class="consensus-box">
              <h5 style="font-size: 0.95rem; font-weight: 800; color: #1e3a8a; margin-bottom: 8px;">
                <i class="fa-solid fa-scale-balanced"></i> 【小組研討共識結論與綜合策略】：
              </h5>
              <textarea id="$idCon" class="activity-textarea" style="min-height: 90px;" placeholder="經過充分溝通辯論後，我們小組達成的折衷平衡方案或生活行動守則是..."></textarea>
            </div>
          </div>
        </div>
      </section>
"@
}

foreach ($s in $sheets) {
    $baseName = $s.BaseName
    $htmlPath = Join-Path $rootDir "$baseName.html"
    if (-not (Test-Path $htmlPath)) { continue }
    
    Write-Output "Enriching HTML for: $baseName ..."
    $content = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
    
    # 1. Update Objectives in HTML
    $objItems = ""
    foreach ($obj in $s.Objectives) {
        $objItems += "            <li><i class=`"fa-solid fa-circle-check`"></i> $obj</li>`n"
    }
    $objRegex = [regex]::new('(<ul class="objectives-list">)[\s\S]*?(</ul>)')
    if ($objRegex.IsMatch($content)) {
        $content = $objRegex.Replace($content, "`$1`n$objItems          `$2", 1)
    }
    
    # 2. Build Part 1 & Part 2 & Part 3 HTML
    $prefixMap = @{
        "夢想的起點-借貸與金融信用(高中)" = "dream"
        "家的撲滿-理財投資（國中）" = "piggy"
        "支付的選擇-金錢規劃（國中）" = "payment"
        "新手上路-保險與風險管理(高中)" = "insurance"
        "曼尼特務-理財投資(高中)" = "agent"
        "理財成長記-借貸與信用（國小）" = "growth"
        "防制金融詐騙影片-流量陷阱(國中)" = "traffic"
        "防制金融詐騙影片-誰偷走了我的名字(國小)" = "identity"
        "防制金融詐騙影片-黑幕帳戶(高中)" = "dark"
    }
    $prefix = if ($prefixMap.ContainsKey($baseName)) { $prefixMap[$baseName] } else { "ws" }
    $quizHtml = Build-QuizHtml $s.Quiz
    $discHtml = Build-DiscussionsHtml $s.Discussions $prefix
    $groupHtml = Build-GroupActivityHtml $s.Activity $prefix
    
    # Concept tags
    $tagsHtml = ""
    foreach ($obj in $s.Objectives) {
        $shortTag = $obj -split '[,，、。]' | Select-Object -First 1
        $tagsHtml += "<span class=`"concept-pill`"><i class=`"fa-solid fa-lightbulb`"></i> $shortTag</span> "
    }
    
    $newTasksBlock = @"
      <!-- Extended Concept Primer -->
      <div class="concept-callout">
        <h4><i class="fa-solid fa-graduation-cap"></i> 本單元延伸金融素養與生活實務核心指標</h4>
        <div class="concept-tag-list">
          $tagsHtml
        </div>
        <p>本學習單不僅涵蓋教學影片中的關鍵內容，更進一步延伸至現代生活必備的金融常識（如信用評分、複利效應、預算分配、保險防護與最新防詐法規）。請仔細閱讀逐字稿並結合生活經驗，完成各項深度思辨與小組互動任務！</p>
      </div>

      <!-- Task 1: 觀念隨堂測驗 -->
      <section class="section-card">
        <div class="section-header">
          <h2 class="section-title"><i class="fa-solid fa-list-check"></i> 第一部分：影片核心與延伸概念隨堂檢測</h2>
          <span style="font-size: 0.85rem; color: #64748b; font-weight: 600;">點選答案後點擊「核對答案」即時解析</span>
        </div>
        <div class="section-body">
$quizHtml        </div>
      </section>

      <!-- Task 2: 延伸深入思辨 -->
      <section class="section-card">
        <div class="section-header" style="background: #fffbeb;">
          <h2 class="section-title" style="color: #b45309;"><i class="fa-solid fa-brain"></i> 第二部分：延伸金融觀念深入思辨題</h2>
          <span style="font-size: 0.85rem; color: #92400e; font-weight: 600;">結合生活實務進行批判思考</span>
        </div>
        <div class="section-body">
$discHtml        </div>
      </section>

$groupHtml
"@
    
    # Replace existing Task 1 & Task 2 up to Task 3 (Canvas)
    $tasksRegex = [regex]::new('(?s)<!-- Extended Concept Primer -->.*?<!-- Task 3: 互動畫布|(?s)<!-- Task 1: 觀念隨堂測驗 -->.*?<!-- Task 3: 互動畫布')
    if ($tasksRegex.IsMatch($content)) {
        $content = $tasksRegex.Replace($content, "$newTasksBlock`n      <!-- Task 3: 互動畫布", 1)
        
        # Clean section headings
        $content = $content.Replace('第三部分：我的', '第四部分：我的')
        $content = $content.Replace('第四部分：單元學習總結', '第五部分：單元學習總結')
        $content = $content.Replace('第五部分：小組互動合作', '第三部分：小組互動合作')
        $content = $content.Replace('第五部分：我的', '第四部分：我的')
        
        [System.IO.File]::WriteAllText($htmlPath, $content, [System.Text.Encoding]::UTF8)
        Write-Output "Successfully updated interactive modules in $baseName.html"
    } else {
        Write-Warning "Could not match tasks regex in $baseName.html"
    }
}

Write-Output "Enrichment completed for all worksheets!"
