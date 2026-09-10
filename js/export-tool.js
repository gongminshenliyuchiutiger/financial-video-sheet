/**
 * 金融基礎教育主題教材教學影片互動式學習單彙整系統
 * 匯出 PDF 與 PNG 引擎 (export-tool.js)
 * （具備「智慧防跨頁切版技術」，徹底防止題目、選項與章節標題被跨頁攔腰切斷）
 */

(function (global) {
  'use strict';

  function getStudentFileName(sheetTitle, ext) {
    const studentName = document.getElementById('studentName')?.value?.trim() || '學生';
    const cleanTitle = (sheetTitle || document.title || '金融學習單')
      .replace(/[\/\?<>\\:\*\|":]/g, '')
      .replace(/\s+/g, '_');
    return `[學習單]_${cleanTitle}_${studentName}.${ext}`;
  }

  function showExportLoading(msg) {
    let loader = document.getElementById('exportLoader');
    if (!loader) {
      loader = document.createElement('div');
      loader.id = 'exportLoader';
      loader.style.cssText = `
        position: fixed;
        top: 0; left: 0; width: 100vw; height: 100vh;
        background: rgba(15, 23, 42, 0.7);
        backdrop-filter: blur(4px);
        z-index: 999999;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: #ffffff;
        font-family: inherit;
        font-size: 1.2rem;
        font-weight: 700;
        gap: 16px;
      `;
      loader.innerHTML = `
        <div style="width: 50px; height: 50px; border: 5px solid #38bdf8; border-top-color: transparent; border-radius: 50%; animation: spin 1s linear infinite;"></div>
        <div id="loaderText">${msg || '正在產生檔案中，請稍候...'}</div>
        <style>@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }</style>
      `;
      document.body.appendChild(loader);
    } else {
      document.getElementById('loaderText').textContent = msg || '正在產生檔案中，請稍候...';
      loader.style.display = 'flex';
    }
  }

  function hideExportLoading() {
    const loader = document.getElementById('exportLoader');
    if (loader) {
      loader.style.display = 'none';
    }
  }

  /**
   * 使用 html2canvas 渲染標準化 A4 寬度紙本，並精準測量所有原子積木元素位置供防跨頁切版
   */
  async function renderWorksheetWithMeasurements(targetElement) {
    await new Promise((resolve) => setTimeout(resolve, 200));

    let measuredBlocks = [];
    let paperClientHeight = 0;

    const canvas = await html2canvas(targetElement, {
      scale: 2, // 2x 高清
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      windowWidth: 1200,
      onclone: (clonedDoc) => {
        const paper = clonedDoc.getElementById('worksheetPaper');
        if (!paper) return;

        // 1. 強制固定標準桌面紙本寬度，杜絕狹窄螢幕時的擠壓變形與跑版
        paper.style.width = '960px';
        paper.style.maxWidth = '960px';
        paper.style.minWidth = '960px';
        paper.style.margin = '0 auto';
        paper.style.boxSizing = 'border-box';
        paper.style.boxShadow = 'none';
        paper.style.borderRadius = '0';
        paper.style.border = 'none';
        paper.style.padding = '36px 40px';

        // 2. 隱藏不應出現在作業紙上的網頁按鈕與折疊區
        paper.querySelectorAll('.btn-play-video, .btn-check-answer, .canvas-toolbar, .transcript-accordion').forEach(el => {
          el.style.display = 'none';
        });

        // 3. 確保手繪畫布完整複製原始 Canvas 圖像數據
        const origCanvas = targetElement.querySelector('#worksheetCanvas');
        const clonedCanvas = paper.querySelector('#worksheetCanvas');
        if (origCanvas && clonedCanvas) {
          clonedCanvas.width = origCanvas.width;
          clonedCanvas.height = origCanvas.height;
          const ctx = clonedCanvas.getContext('2d');
          ctx.drawImage(origCanvas, 0, 0);
        }

        // 4. 將 input 替換為乾淨對齊的文字 Div（徹底解決原生日期控件截斷問題）
        paper.querySelectorAll('.info-field-input').forEach(input => {
          const val = input.value || input.placeholder || '';
          const isPlaceholder = !input.value;
          const textDiv = clonedDoc.createElement('div');
          textDiv.textContent = val;
          textDiv.style.cssText = `
            height: 38px;
            line-height: 38px;
            padding: 0 10px;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            background: #ffffff;
            color: ${isPlaceholder ? '#94a3b8' : '#1e293b'};
            font-size: 14px;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            box-sizing: border-box;
          `;
          input.parentNode.replaceChild(textDiv, input);
        });

        // 5. 將 textarea 替換為自動延展的文字容器，避免滾動條或文字被截斷
        paper.querySelectorAll('.reflection-textarea').forEach(textarea => {
          const val = textarea.value || textarea.placeholder || '';
          const isPlaceholder = !textarea.value;
          const textDiv = clonedDoc.createElement('div');
          textDiv.textContent = val;
          textDiv.style.cssText = `
            min-height: 80px;
            padding: 12px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            background: #ffffff;
            color: ${isPlaceholder ? '#94a3b8' : '#1e293b'};
            font-size: 14px;
            line-height: 1.6;
            white-space: pre-wrap;
            word-break: break-word;
            box-sizing: border-box;
          `;
          textarea.parentNode.replaceChild(textDiv, textarea);
        });

        // 6. 強調已選取選項的高亮樣式
        paper.querySelectorAll('input[type="radio"]:checked, input[type="checkbox"]:checked').forEach(checkedInput => {
          const label = checkedInput.closest('.option-label');
          if (label) {
            label.style.backgroundColor = '#eff6ff';
            label.style.borderColor = '#1e3a8a';
            label.style.fontWeight = '700';
          }
        });

        // 7. 保持已作答解析區域呈現
        paper.querySelectorAll('.explanation-box').forEach(exp => {
          if (exp.innerHTML.trim() !== '') {
            exp.style.display = 'flex';
          }
        });

        // 8. 學生自我星級評分固定呈現
        paper.querySelectorAll('.stars-rating').forEach(starContainer => {
          const rating = parseInt(starContainer.dataset.rating, 10) || 0;
          starContainer.querySelectorAll('.star-btn').forEach((btn, i) => {
            btn.style.color = (i < rating) ? '#f59e0b' : '#cbd5e1';
          });
        });

        // 9. 精準測量所有原子積木元素（不可分割單元）
        const paperRect = paper.getBoundingClientRect();
        paperClientHeight = paperRect.height;
        measuredBlocks = [];

        // 選擇不可分割之原子元素，按出現順序由上而下排列
        const atomicSelectors = [
          '.sheet-header',
          '.section-header',
          '.question-block',
          '.canvas-activity-card',
          '.eval-section'
        ];

        paper.querySelectorAll(atomicSelectors.join(', ')).forEach(el => {
          const r = el.getBoundingClientRect();
          measuredBlocks.push({
            top: r.top - paperRect.top,
            bottom: r.bottom - paperRect.top,
            height: r.height,
            isSectionHeader: el.classList.contains('section-header'),
            isQuestionBlock: el.classList.contains('question-block'),
            isCanvasCard: el.classList.contains('canvas-activity-card'),
            isHeader: el.classList.contains('sheet-header'),
            isEval: el.classList.contains('eval-section')
          });
        });

        // 按垂直座標從小到大排序
        measuredBlocks.sort((a, b) => a.top - b.top);
      }
    });

    return { canvas, measuredBlocks, paperClientHeight };
  }

  async function exportToPNG(sheetTitle) {
    const targetElement = document.getElementById('worksheetPaper');
    if (!targetElement) {
      alert('找不到學習單內容容器！');
      return;
    }

    if (typeof html2canvas === 'undefined') {
      alert('html2canvas 函式庫載入失敗，請檢查網路連線。');
      return;
    }

    showExportLoading('正在產生高解析度 PNG 圖片...');

    try {
      const { canvas } = await renderWorksheetWithMeasurements(targetElement);

      canvas.toBlob((blob) => {
        if (!blob) {
          throw new Error('Blob conversion failed');
        }
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = getStudentFileName(sheetTitle, 'png');
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        hideExportLoading();
      }, 'image/png', 0.95);
    } catch (err) {
      console.error('PNG export error:', err);
      alert('產生 PNG 發生錯誤，請稍後再試。');
      hideExportLoading();
    }
  }

  async function exportToPDF(sheetTitle) {
    const targetElement = document.getElementById('worksheetPaper');
    if (!targetElement) {
      alert('找不到學習單內容容器！');
      return;
    }

    if (typeof html2canvas === 'undefined' || !window.jspdf || !window.jspdf.jsPDF) {
      alert('PDF 匯出工具載入中，請稍候再試...');
      return;
    }

    showExportLoading('正在產生標準 A4 PDF 文件（智慧防跨頁排版）...');

    try {
      const { canvas, measuredBlocks, paperClientHeight } = await renderWorksheetWithMeasurements(targetElement);

      const { jsPDF } = window.jspdf;
      const pdf = new jsPDF('p', 'mm', 'a4');
      const pageWidth = 210;
      const pageHeight = 297;
      const margin = 10;
      const usableWidth = pageWidth - (margin * 2); // 190mm
      const usableHeight = pageHeight - (margin * 2); // 277mm

      const scale = canvas.height / (paperClientHeight || 1);

      // 將 DOM 測量座標轉換為 Canvas 實際像素高度
      const canvasBlocks = measuredBlocks.map(b => ({
        canvasTop: b.top * scale,
        canvasBottom: b.bottom * scale,
        isSectionHeader: b.isSectionHeader,
        isQuestionBlock: b.isQuestionBlock,
        isCanvasCard: b.isCanvasCard,
        isHeader: b.isHeader,
        isEval: b.isEval
      }));

      // 單頁 A4 在該 canvas 上最大可容納的像素高度
      const maxPageCanvasHeight = (canvas.width / usableWidth) * usableHeight;

      let currentY = 0;
      let pageIndex = 0;

      while (currentY < canvas.height - 15) {
        let targetCutY = currentY + maxPageCanvasHeight;

        if (targetCutY >= canvas.height) {
          targetCutY = canvas.height;
        } else {
          // 智慧防跨頁演算法：尋找是否有任何題目或章節被 targetCutY 橫切
          let safeCutY = targetCutY;

          for (let i = 0; i < canvasBlocks.length; i++) {
            const block = canvasBlocks[i];

            // 條件：當前區塊橫跨了分頁線
            if (block.canvasTop < targetCutY && block.canvasBottom > targetCutY) {
              // 且起點在頁面安全範圍內（避免極大元素無限循環）
              if (block.canvasTop > currentY + 120) {
                safeCutY = block.canvasTop - 10; // 提早在此區塊上方切頁！將整題移至下一頁

                // 防孤兒標題 (Orphan Header Protection)：
                // 若上一元素是章節標題 (.section-header)，且距離當前題目不到 120px，
                // 說明該標題本頁只有這一題，此時連同章節標題一起移到下一頁！
                if (i > 0) {
                  const prev = canvasBlocks[i - 1];
                  if (prev.isSectionHeader && prev.canvasTop > currentY + 60 && prev.canvasTop < safeCutY) {
                    safeCutY = prev.canvasTop - 10;
                  }
                }
                break;
              }
            } else if (block.isSectionHeader && block.canvasTop < targetCutY && block.canvasTop > targetCutY - 100) {
              // 若章節標題剛好落在頁面最底端 100px 以內（標題後面無法容納題目），也直接提早切頁！
              if (block.canvasTop > currentY + 120) {
                safeCutY = block.canvasTop - 10;
                break;
              }
            }
          }

          targetCutY = safeCutY;
        }

        const sliceHeight = targetCutY - currentY;
        if (sliceHeight <= 0) break;

        // 建立該頁的獨立無縫 Canvas
        const pageCanvas = document.createElement('canvas');
        pageCanvas.width = canvas.width;
        pageCanvas.height = sliceHeight;
        const pCtx = pageCanvas.getContext('2d');
        pCtx.fillStyle = '#ffffff';
        pCtx.fillRect(0, 0, pageCanvas.width, pageCanvas.height);
        pCtx.drawImage(
          canvas,
          0, currentY, canvas.width, sliceHeight,
          0, 0, canvas.width, sliceHeight
        );

        const sliceData = pageCanvas.toDataURL('image/jpeg', 0.95);
        const sliceMmHeight = (sliceHeight * usableWidth) / canvas.width;

        if (pageIndex > 0) {
          pdf.addPage();
        }
        pdf.addImage(sliceData, 'JPEG', margin, margin, usableWidth, sliceMmHeight);

        currentY = targetCutY;
        pageIndex++;
      }

      pdf.save(getStudentFileName(sheetTitle, 'pdf'));
      hideExportLoading();
    } catch (err) {
      console.error('PDF export error:', err);
      alert('產生 PDF 發生錯誤，請稍候重試。');
      hideExportLoading();
    }
  }

  function setupExportButtons(sheetTitle) {
    const btnPng = document.getElementById('btnExportPNG');
    const btnPdf = document.getElementById('btnExportPDF');

    if (btnPng) {
      btnPng.addEventListener('click', () => exportToPNG(sheetTitle));
    }
    if (btnPdf) {
      btnPdf.addEventListener('click', () => exportToPDF(sheetTitle));
    }
  }

  global.WorksheetExporter = {
    exportToPNG,
    exportToPDF,
    setupExportButtons
  };
})(window);
