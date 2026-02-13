// Copy code to clipboard — targets terminal blocks, YAML blocks, skill file content, and dark prompt boxes
(function () {
  'use strict';

  var TARGETS = [
    '.terminal-block',
    '.yaml-block',
    '.skill-file pre',
    '.prompt-box-dark'
  ];

  function addCopyButtons() {
    TARGETS.forEach(function (selector) {
      var blocks = document.querySelectorAll(selector);
      blocks.forEach(function (block) {
        // Skip if already wrapped
        if (block.parentNode.classList.contains('copy-wrapper')) return;

        var wrapper = document.createElement('div');
        wrapper.className = 'copy-wrapper';
        block.parentNode.insertBefore(wrapper, block);
        wrapper.appendChild(block);

        var btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.textContent = 'Copy';
        btn.setAttribute('aria-label', 'Copy code to clipboard');
        btn.addEventListener('click', function () {
          copyText(block, btn);
        });

        wrapper.appendChild(btn);
      });
    });
  }

  function copyText(block, btn) {
    var text = block.textContent;

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () {
        showCopied(btn);
      }).catch(function () {
        fallbackCopy(text, btn);
      });
    } else {
      fallbackCopy(text, btn);
    }
  }

  function fallbackCopy(text, btn) {
    var textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand('copy');
      showCopied(btn);
    } catch (e) {
      // Silent fail
    }
    document.body.removeChild(textarea);
  }

  function showCopied(btn) {
    var original = btn.textContent;
    btn.textContent = 'Copied!';
    btn.style.opacity = '1';
    setTimeout(function () {
      btn.textContent = original;
      btn.style.opacity = '';
    }, 2000);
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons);
  } else {
    addCopyButtons();
  }
})();
