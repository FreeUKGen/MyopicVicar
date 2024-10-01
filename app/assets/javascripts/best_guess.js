$(document).ready(function() {
	/*Hide citation blocks unless citation type is selected*/
	const citations = ['wikitree_inline', 'wikitree_ref', 'familytree', 'evidence_explained', 'wikipedia'];
	function hide_citation_block(index, cite){
	  $(`#${cite}_citation_container`).css("display", "none");
	}
	/* When the user clicks on the button,
	toggle between hiding and showing the dropdown content */
	function citationToggle() {
	  jQuery.each(citations, hide_citation_block);
	  if($('#citation-dropdown').css('display') == 'none') {
	  	$("#citation-dropdown").css('display', 'block');
	  } else {
	  	$("#citation-dropdown").css('display', 'none');
	  }
	}

	$('#citation-toggle').click(citationToggle);

	function citationSwitch(type){
    jQuery.each(citations, hide_citation_block);
    $(`#${type}_citation_container`).toggle();
	}

	function copy(elm) {
	    var button = event.currentTarget || event.srcElement;
	    var btnText = button.innerHTML;
	    var target = document.getElementById(elm);
	    var citation = target.querySelectorAll('.citation_container')[0];
	    var range, select;
	    if (document.createRange) {
	        range = document.createRange();
	        range.selectNode(citation);
	        select = window.getSelection();
	        select.removeAllRanges();
	        select.addRange(range);
	        document.execCommand('copy');
	        select.removeAllRanges();
	    } else {
	        range = document.body.createTextRange();
	        range.moveToElementText(citation);
	        range.select();
	        document.execCommand('copy');
	    }
	    button.innerHTML = "Copied"
	    setTimeout(function(){
	        button.innerHTML = btnText;
	    }, 1000);
	}
});
