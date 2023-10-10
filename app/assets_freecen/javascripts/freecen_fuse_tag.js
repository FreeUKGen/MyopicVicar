$(document).ready(function() {
  //donate cta
  if ((getCookie('donate_cta_flag_new') != null)) {
	  $('head').append('<script async src="https://cdn.fuseplatform.net/publift/tags/2/3270/fuse.js"></script>')
} else {
  ('<script async src="https://cdn.fuseplatform.net/publift/tags/2/3270/fuse.js"></script>').remove()
}
/*CTA code changes ends */
});