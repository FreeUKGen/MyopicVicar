(function() {
  function setupMultiFileUpload() {
    var inputs = document.querySelectorAll('input[type="file"][multiple]#feedback_screenshots, input[type="file"][multiple][data-multi-file-upload]');
    if (!inputs || inputs.length === 0) return;

    inputs.forEach(function(input) {
      if (input.dataset.multiUploadInitialized === "true") return;
      input.dataset.multiUploadInitialized = "true";

      var listId = input.getAttribute('data-list-target') || 'feedback_screenshot_list';
      var list = document.getElementById(listId);
      if (!list) {
        list = document.createElement('ul');
        list.id = listId;
        list.className = 'attached-files-list';
        list.style.listStyle = 'none';
        list.style.padding = '0';
        list.style.marginTop = '8px';
        input.parentNode.appendChild(list);
      }

      var fileQueue = [];

      function formatBytes(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
      }

      function escapeHtml(str) {
        var div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
      }

      function syncInputFiles() {
        if (window.DataTransfer) {
          var dt = new DataTransfer();
          fileQueue.forEach(function(file) {
            dt.items.add(file);
          });
          input.files = dt.files;
        }
      }

      function renderList() {
        list.innerHTML = '';
        if (fileQueue.length === 0) return;

        fileQueue.forEach(function(file, index) {
          var li = document.createElement('li');
          li.className = 'attached-file-item';
          li.style.display = 'flex';
          li.style.alignItems = 'center';
          li.style.justifyContent = 'space-between';
          li.style.padding = '6px 10px';
          li.style.marginBottom = '5px';
          li.style.background = '#f7f7f7';
          li.style.border = '1px solid #ddd';
          li.style.borderRadius = '3px';

          var infoSpan = document.createElement('span');
          infoSpan.className = 'file-info';
          infoSpan.style.wordBreak = 'break-all';
          infoSpan.innerHTML = '<i class="fa fa-image" style="margin-right: 6px; color: #555;"></i>' +
            '<strong>' + escapeHtml(file.name) + '</strong> ' +
            '<small style="color: #777;">(' + formatBytes(file.size) + ')</small>';

          var removeBtn = document.createElement('button');
          removeBtn.type = 'button';
          removeBtn.className = 'btn-remove-file';
          removeBtn.title = 'Remove file';
          removeBtn.style.background = 'none';
          removeBtn.style.border = 'none';
          removeBtn.style.cursor = 'pointer';
          removeBtn.style.padding = '0 5px';
          removeBtn.style.fontSize = '18px';
          removeBtn.style.fontWeight = 'bold';
          removeBtn.style.color = '#cc0000';
          removeBtn.style.lineHeight = '1';
          removeBtn.innerHTML = '<i class="fa fa-times" style="color: #cc0000;"></i>';

          removeBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            fileQueue.splice(index, 1);
            syncInputFiles();
            renderList();
          });

          li.appendChild(infoSpan);
          li.appendChild(removeBtn);
          list.appendChild(li);
        });
      }

      input.addEventListener('change', function(e) {
        var newFiles = Array.from(input.files || []);
        newFiles.forEach(function(newFile) {
          var exists = fileQueue.some(function(f) {
            return f.name === newFile.name && f.size === newFile.size && f.lastModified === newFile.lastModified;
          });
          if (!exists) {
            fileQueue.push(newFile);
          }
        });
        syncInputFiles();
        renderList();
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupMultiFileUpload);
  } else {
    setupMultiFileUpload();
  }
  document.addEventListener('turbolinks:load', setupMultiFileUpload);
})();
