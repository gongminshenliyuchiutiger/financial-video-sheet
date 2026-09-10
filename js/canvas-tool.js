/**
 * 金融基礎教育主題教材教學影片互動式學習單彙整系統
 * 手繪塗鴉與寫字畫布引擎 (canvas-tool.js)
 */

(function (global) {
  'use strict';

  class WorksheetCanvas {
    constructor(canvasId, storageKey) {
      this.canvas = document.getElementById(canvasId);
      if (!this.canvas) return;

      this.ctx = this.canvas.getContext('2d', { willReadFrequently: true });
      this.storageKey = storageKey || ('worksheet_canvas_' + window.location.pathname);

      // Drawing state
      this.isDrawing = false;
      this.currentMode = 'pen'; // 'pen', 'highlighter', 'eraser'
      this.currentColor = '#1e293b';
      this.currentWidth = 4;
      this.history = [];
      this.redoStack = [];
      this.maxHistory = 20;

      // Coordinate tracking
      this.lastX = 0;
      this.lastY = 0;

      this.init();
    }

    init() {
      this.resizeCanvas();
      window.addEventListener('resize', () => this.handleResize());

      this.bindEvents();
      this.bindToolbar();
      this.restoreFromStorage();
      this.saveState();
    }

    resizeCanvas() {
      const rect = this.canvas.parentElement.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      
      const width = rect.width || 800;
      const height = rect.height || 380;

      // Save content before resize
      let tempImage = null;
      if (this.canvas.width > 0 && this.canvas.height > 0) {
        try {
          tempImage = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
        } catch (e) {}
      }

      this.canvas.width = width * dpr;
      this.canvas.height = height * dpr;
      this.canvas.style.width = width + 'px';
      this.canvas.style.height = height + 'px';

      this.ctx.scale(dpr, dpr);
      this.ctx.lineCap = 'round';
      this.ctx.lineJoin = 'round';

      // Restore
      if (tempImage) {
        this.ctx.putImageData(tempImage, 0, 0);
      }
    }

    handleResize() {
      // Debounce resize
      clearTimeout(this.resizeTimer);
      this.resizeTimer = setTimeout(() => {
        const dataUrl = this.canvas.toDataURL();
        this.resizeCanvas();
        const img = new Image();
        img.onload = () => {
          const dpr = window.devicePixelRatio || 1;
          this.ctx.drawImage(img, 0, 0, this.canvas.width / dpr, this.canvas.height / dpr);
        };
        img.src = dataUrl;
      }, 200);
    }

    getPointerPos(e) {
      const rect = this.canvas.getBoundingClientRect();
      let clientX = e.clientX;
      let clientY = e.clientY;

      if (e.touches && e.touches.length > 0) {
        clientX = e.touches[0].clientX;
        clientY = e.touches[0].clientY;
      }

      return {
        x: clientX - rect.left,
        y: clientY - rect.top
      };
    }

    bindEvents() {
      const canvas = this.canvas;

      const start = (e) => {
        if (e.button && e.button !== 0) return;
        this.isDrawing = true;
        const pos = this.getPointerPos(e);
        this.lastX = pos.x;
        this.lastY = pos.y;

        // Draw a dot on simple click
        this.draw(pos.x, pos.y);
      };

      const move = (e) => {
        if (!this.isDrawing) return;
        const pos = this.getPointerPos(e);
        this.draw(pos.x, pos.y);
        this.lastX = pos.x;
        this.lastY = pos.y;
        e.preventDefault();
      };

      const end = () => {
        if (this.isDrawing) {
          this.isDrawing = false;
          this.saveState();
          this.saveToStorage();
        }
      };

      // Pointer events
      canvas.addEventListener('pointerdown', start);
      canvas.addEventListener('pointermove', move);
      canvas.addEventListener('pointerup', end);
      canvas.addEventListener('pointercancel', end);
      canvas.addEventListener('pointerleave', end);
    }

    draw(x, y) {
      const ctx = this.ctx;
      ctx.beginPath();
      ctx.moveTo(this.lastX, this.lastY);
      ctx.lineTo(x, y);

      if (this.currentMode === 'eraser') {
        ctx.globalCompositeOperation = 'destination-out';
        ctx.strokeStyle = 'rgba(0,0,0,1)';
        ctx.lineWidth = this.currentWidth * 4;
      } else if (this.currentMode === 'highlighter') {
        ctx.globalCompositeOperation = 'source-over';
        ctx.strokeStyle = this.hexToRgba(this.currentColor, 0.35);
        ctx.lineWidth = this.currentWidth * 3.5;
      } else {
        ctx.globalCompositeOperation = 'source-over';
        ctx.strokeStyle = this.currentColor;
        ctx.lineWidth = this.currentWidth;
      }

      ctx.stroke();
      ctx.closePath();
    }

    hexToRgba(hex, alpha) {
      let c = hex.replace('#', '');
      if (c.length === 3) {
        c = c.split('').map(char => char + char).join('');
      }
      const num = parseInt(c, 16);
      return `rgba(${(num >> 16) & 255}, ${(num >> 8) & 255}, ${num & 255}, ${alpha})`;
    }

    saveState() {
      this.redoStack = [];
      const dpr = window.devicePixelRatio || 1;
      const imgData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
      this.history.push(imgData);

      if (this.history.length > this.maxHistory) {
        this.history.shift();
      }
    }

    undo() {
      if (this.history.length > 1) {
        const current = this.history.pop();
        this.redoStack.push(current);
        const prev = this.history[this.history.length - 1];
        this.ctx.putImageData(prev, 0, 0);
        this.saveToStorage();
      }
    }

    redo() {
      if (this.redoStack.length > 0) {
        const next = this.redoStack.pop();
        this.history.push(next);
        this.ctx.putImageData(next, 0, 0);
        this.saveToStorage();
      }
    }

    clear() {
      if (confirm('確定要清空畫布嗎？')) {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.saveState();
        localStorage.removeItem(this.storageKey);
      }
    }

    saveToStorage() {
      try {
        const dataUrl = this.canvas.toDataURL();
        localStorage.setItem(this.storageKey, dataUrl);
      } catch (e) {
        console.warn('Storage quota exceeded or error saving canvas', e);
      }
    }

    restoreFromStorage() {
      const saved = localStorage.getItem(this.storageKey);
      if (saved) {
        const img = new Image();
        img.onload = () => {
          const dpr = window.devicePixelRatio || 1;
          this.ctx.drawImage(img, 0, 0, this.canvas.width / dpr, this.canvas.height / dpr);
          this.saveState();
        };
        img.src = saved;
      }
    }

    bindToolbar() {
      // Tools: Pen, Highlighter, Eraser
      const toolBtns = document.querySelectorAll('.canvas-tool-btn[data-tool]');
      toolBtns.forEach(btn => {
        btn.addEventListener('click', () => {
          toolBtns.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          this.currentMode = btn.dataset.tool;
        });
      });

      // Colors
      const swatches = document.querySelectorAll('.color-swatch');
      swatches.forEach(swatch => {
        swatch.addEventListener('click', () => {
          swatches.forEach(s => s.classList.remove('active'));
          swatch.classList.add('active');
          this.currentColor = swatch.dataset.color;
          if (this.currentMode === 'eraser') {
            document.querySelector('[data-tool="pen"]')?.click();
          }
        });
      });

      const customColor = document.getElementById('customColorPicker');
      if (customColor) {
        customColor.addEventListener('input', (e) => {
          swatches.forEach(s => s.classList.remove('active'));
          this.currentColor = e.target.value;
          if (this.currentMode === 'eraser') {
            document.querySelector('[data-tool="pen"]')?.click();
          }
        });
      }

      // Stroke size
      const sizeSelect = document.getElementById('brushSizeSelect');
      if (sizeSelect) {
        sizeSelect.addEventListener('change', (e) => {
          this.currentWidth = parseInt(e.target.value, 10) || 4;
        });
      }

      // Undo / Redo / Clear
      document.getElementById('canvasUndoBtn')?.addEventListener('click', () => this.undo());
      document.getElementById('canvasRedoBtn')?.addEventListener('click', () => this.redo());
      document.getElementById('canvasClearBtn')?.addEventListener('click', () => this.clear());
    }
  }

  global.WorksheetCanvas = WorksheetCanvas;
})(window);
