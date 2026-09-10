/**
 * 金融基礎教育主題教材教學影片互動式學習單彙整系統
 * 吉祥物拖曳、霓虹特效控制模組 (mascot.js)
 * （已依需求移除對話文字氣泡，專注於炫彩霓虹、抖動與自由拖曳體驗）
 */

(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', () => {
    initMascot();
  });

  function initMascot() {
    let mascot = document.getElementById('liyuChillGuyMascot');
    if (!mascot) {
      mascot = createMascotElement();
      document.body.appendChild(mascot);
    }

    setupDraggable(mascot);
  }

  function createMascotElement() {
    const container = document.createElement('div');
    container.id = 'liyuChillGuyMascot';
    container.className = 'mascot-container';
    container.setAttribute('role', 'region');
    container.setAttribute('aria-label', '鯉魚秋老虎吉祥物');

    container.innerHTML = `
      <div class="mascot-image-wrapper">
        <img src="image/LiyuChillGuy.svg" alt="吉祥物 快樂鯉魚秋老虎" class="mascot-img" draggable="false" />
      </div>
      <div class="mascot-drag-hint">
        <i class="fa-solid fa-up-down-left-right"></i> 可拖曳
      </div>
    `;

    return container;
  }

  function setupDraggable(element) {
    let isDragging = false;
    let startX = 0;
    let startY = 0;
    let initialLeft = 0;
    let initialTop = 0;

    // Restore position from sessionStorage if exists
    const savedPos = sessionStorage.getItem('mascot_pos');
    if (savedPos) {
      try {
        const { left, top } = JSON.parse(savedPos);
        const maxL = window.innerWidth - (element.offsetWidth || 96) - 10;
        const maxT = window.innerHeight - (element.offsetHeight || 130) - 10;
        const clampedL = Math.max(10, Math.min(left, maxL));
        const clampedT = Math.max(10, Math.min(top, maxT));
        element.style.left = clampedL + 'px';
        element.style.top = clampedT + 'px';
        element.style.bottom = 'auto';
      } catch (e) {
        console.warn('Failed to restore mascot position', e);
      }
    }

    const onPointerDown = (e) => {
      if (e.button && e.button !== 0) return;

      isDragging = true;
      element.classList.add('is-dragging');

      const rect = element.getBoundingClientRect();
      initialLeft = rect.left;
      initialTop = rect.top;
      startX = e.clientX || (e.touches && e.touches[0].clientX);
      startY = e.clientY || (e.touches && e.touches[0].clientY);

      element.style.left = initialLeft + 'px';
      element.style.top = initialTop + 'px';
      element.style.bottom = 'auto';
      element.style.right = 'auto';

      document.addEventListener('pointermove', onPointerMove, { passive: false });
      document.addEventListener('pointerup', onPointerUp);
      document.addEventListener('pointercancel', onPointerUp);
    };

    const onPointerMove = (e) => {
      if (!isDragging) return;

      const clientX = e.clientX || (e.touches && e.touches[0].clientX);
      const clientY = e.clientY || (e.touches && e.touches[0].clientY);

      const dx = clientX - startX;
      const dy = clientY - startY;

      let newLeft = initialLeft + dx;
      let newTop = initialTop + dy;

      const elWidth = element.offsetWidth || 96;
      const elHeight = element.offsetHeight || 130;
      const minX = 8;
      const minY = 8;
      const maxX = window.innerWidth - elWidth - 8;
      const maxY = window.innerHeight - elHeight - 8;

      newLeft = Math.max(minX, Math.min(newLeft, maxX));
      newTop = Math.max(minY, Math.min(newTop, maxY));

      element.style.left = newLeft + 'px';
      element.style.top = newTop + 'px';

      e.preventDefault();
    };

    const onPointerUp = () => {
      if (!isDragging) return;
      isDragging = false;
      element.classList.remove('is-dragging');

      document.removeEventListener('pointermove', onPointerMove);
      document.removeEventListener('pointerup', onPointerUp);
      document.removeEventListener('pointercancel', onPointerUp);

      const rect = element.getBoundingClientRect();
      sessionStorage.setItem('mascot_pos', JSON.stringify({ left: rect.left, top: rect.top }));
    };

    element.addEventListener('pointerdown', onPointerDown);

    window.addEventListener('resize', () => {
      const rect = element.getBoundingClientRect();
      const elWidth = element.offsetWidth || 96;
      const elHeight = element.offsetHeight || 130;
      const maxL = window.innerWidth - elWidth - 8;
      const maxT = window.innerHeight - elHeight - 8;

      if (rect.left > maxL || rect.top > maxT) {
        element.style.left = Math.max(8, Math.min(rect.left, maxL)) + 'px';
        element.style.top = Math.max(8, Math.min(rect.top, maxT)) + 'px';
      }
    });
  }
})();
