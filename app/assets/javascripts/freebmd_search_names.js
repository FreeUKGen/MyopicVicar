// FreeBMD search form: jQuery UI autocomplete sets autocomplete="off" on the name fields, so
// browsers do not restore them when the user comes Back to the form. Keep them for this tab instead (#905).
// resetBmdSearchForm in search_queries/_form_freebmd.html.erb clears the saved names.
$(function () {
  // FreeREG and FreeCEN search forms share these ids, so only run on the FreeBMD form
  if (!$('#search_query_bmd_record_type_birth').length) { return; }

  var nameFields = ['first_name', 'last_name'];
  var storageKey = 'bmd_search_names';

  $('#new_search_query').on('submit', function () {
    var names = {};
    nameFields.forEach(function (id) { names[id] = $('#' + id).val(); });
    try { sessionStorage.setItem(storageKey, JSON.stringify(names)); } catch (e) {}
  });

  window.addEventListener('pageshow', function (event) {
    var nav = window.performance && performance.getEntriesByType ? performance.getEntriesByType('navigation')[0] : null;
    if (!event.persisted && !(nav && nav.type === 'back_forward')) { return; }
    var names = null;
    try { names = JSON.parse(sessionStorage.getItem(storageKey)); } catch (e) {}
    if (!names) { return; }
    nameFields.forEach(function (id) {
      var $field = $('#' + id);
      if ($field.val() === '' && names[id]) { $field.val(names[id]); }
    });
  });
});
