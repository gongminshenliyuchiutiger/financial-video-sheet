/**
 * 金融基礎教育主題教材教學影片互動式學習單彙整系統
 * 學習單互動邏輯、評分與暫存模組 (worksheet.js)
 */

(function () {
  'use strict';

  const STORAGE_PREFIX = 'fws_form_' + window.location.pathname;

  document.addEventListener('DOMContentLoaded', () => {
    initStudentInfo();
    initQuizzes();
    initTranscriptViewer();
    initStarRatings();
    initResetButton();
    restoreFormData();
  });

  // Student Info auto-save & default date
  function initStudentInfo() {
    const dateInput = document.getElementById('sheetDate');
    if (dateInput && !dateInput.value) {
      const today = new Date().toISOString().split('T')[0];
      dateInput.value = today;
    }

    const inputs = document.querySelectorAll('.info-field-input, .reflection-textarea, .activity-textarea');
    inputs.forEach(input => {
      input.addEventListener('input', () => {
        saveFormData();
      });
    });
  }

  // Quiz checking with feedback
  function initQuizzes() {
    const questionBlocks = document.querySelectorAll('.question-block');

    questionBlocks.forEach(block => {
      const radios = block.querySelectorAll('input[type="radio"], input[type="checkbox"]');
      const checkBtn = block.querySelector('.btn-check-answer');
      const explanation = block.querySelector('.explanation-box');

      radios.forEach(radio => {
        radio.addEventListener('change', () => {
          // Highlight selected label
          const labels = block.querySelectorAll('.option-label');
          labels.forEach(l => l.classList.remove('selected'));
          if (radio.checked) {
            radio.closest('.option-label')?.classList.add('selected');
          }
          saveFormData();
        });
      });

      if (checkBtn && explanation) {
        checkBtn.addEventListener('click', () => {
          const selected = block.querySelector('input[type="radio"]:checked');
          if (!selected) {
            alert('請先選擇一個答案再進行核對喔！');
            return;
          }

          const isCorrect = selected.value === block.dataset.correct;
          explanation.className = 'explanation-box ' + (isCorrect ? 'correct' : 'incorrect');
          
          const icon = isCorrect ? '<i class="fa-solid fa-circle-check"></i>' : '<i class="fa-solid fa-circle-xmark"></i>';
          const title = isCorrect ? '<strong>答對了！恭喜你掌握了核心觀念！</strong><br>' : '<strong>答錯了，別氣餒！讓我們看看觀念解析：</strong><br>';
          
          explanation.innerHTML = `<div>${icon}</div><div>${title}${block.dataset.explanation || ''}</div>`;
          explanation.style.display = 'flex';
          
          saveFormData();
        });
      }
    });
  }

  // Transcript Collapsible & Realtime Search
  function initTranscriptViewer() {
    const toggleBtn = document.querySelector('.transcript-summary-toggle');
    const panel = document.querySelector('.transcript-content-panel');
    const searchInput = document.getElementById('transcriptSearch');

    if (toggleBtn && panel) {
      toggleBtn.addEventListener('click', () => {
        const isOpen = panel.style.display === 'block';
        panel.style.display = isOpen ? 'none' : 'block';
        toggleBtn.classList.toggle('open', !isOpen);
      });
    }

    if (searchInput && panel) {
      searchInput.addEventListener('input', (e) => {
        const query = e.target.value.trim().toLowerCase();
        const items = panel.querySelectorAll('.transcript-dialogue-item');

        items.forEach(item => {
          const text = item.textContent.toLowerCase();
          if (!query || text.includes(query)) {
            item.style.display = '';
          } else {
            item.style.display = 'none';
          }
        });
      });
    }
  }

  // Star Ratings
  function initStarRatings() {
    const ratingContainers = document.querySelectorAll('.stars-rating');
    ratingContainers.forEach(container => {
      const stars = container.querySelectorAll('.star-btn');
      stars.forEach((star, index) => {
        star.addEventListener('click', () => {
          stars.forEach((s, i) => {
            s.classList.toggle('active', i <= index);
          });
          container.dataset.rating = index + 1;
          saveFormData();
        });
      });
    });
  }

  // Save / Restore
  function saveFormData() {
    const data = {
      inputs: {},
      radios: {},
      textareas: {},
      ratings: {}
    };

    document.querySelectorAll('.info-field-input').forEach(input => {
      if (input.id) data.inputs[input.id] = input.value;
    });

    document.querySelectorAll('.reflection-textarea, .activity-textarea').forEach(ta => {
      if (ta.id) data.textareas[ta.id] = ta.value;
    });

    document.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
      if (radio.name) data.radios[radio.name] = radio.value;
    });

    document.querySelectorAll('.stars-rating').forEach((container, idx) => {
      data.ratings[idx] = container.dataset.rating || 0;
    });

    try {
      localStorage.setItem(STORAGE_PREFIX, JSON.stringify(data));
    } catch (e) {
      console.warn('LocalStorage error', e);
    }
  }

  function restoreFormData() {
    const raw = localStorage.getItem(STORAGE_PREFIX);
    if (!raw) return;

    try {
      const data = JSON.parse(raw);

      if (data.inputs) {
        Object.entries(data.inputs).forEach(([id, val]) => {
          const el = document.getElementById(id);
          if (el) el.value = val;
        });
      }

      if (data.textareas) {
        Object.entries(data.textareas).forEach(([id, val]) => {
          const el = document.getElementById(id);
          if (el) el.value = val;
        });
      }

      if (data.radios) {
        Object.entries(data.radios).forEach(([name, val]) => {
          const radio = document.querySelector(`input[name="${name}"][value="${val}"]`);
          if (radio) {
            radio.checked = true;
            radio.closest('.option-label')?.classList.add('selected');
          }
        });
      }

      if (data.ratings) {
        const ratingContainers = document.querySelectorAll('.stars-rating');
        Object.entries(data.ratings).forEach(([idx, score]) => {
          const container = ratingContainers[idx];
          if (container) {
            container.dataset.rating = score;
            const stars = container.querySelectorAll('.star-btn');
            stars.forEach((s, i) => {
              s.classList.toggle('active', i < score);
            });
          }
        });
      }
    } catch (e) {
      console.warn('Failed to parse saved form data', e);
    }
  }

  function initResetButton() {
    const btnReset = document.getElementById('btnResetSheet');
    if (btnReset) {
      btnReset.addEventListener('click', () => {
        if (confirm('確定要清除此學習單的所有作答內容與手繪塗鴉嗎？')) {
          localStorage.removeItem(STORAGE_PREFIX);
          const canvasKey = 'worksheet_canvas_' + window.location.pathname;
          localStorage.removeItem(canvasKey);
          window.location.reload();
        }
      });
    }
  }
})();
