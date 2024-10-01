$(document).ready(function() {
	/*Hide citation blocks unless citation type is selected*/
	const citations = ['wikitree_inline', 'wikitree_ref', 'familytree', 'evidence_explained', 'wikipedia'];
	function hide_citation_block(cite){
	  $(`#${cite}_citation_container`).css("display", "none");
	}
	/* When the user clicks on the button,
	toggle between hiding and showing the dropdown content */
	function citationToggle() {
	  jQuery.each(citation, hide_citation_block);
	  $("#citation-dropdown").toggle();
	}

	$('#citation-toggle').click(citationToggle);

	function citationSwitch(type){
    var citation_container = document.getElementById(`${type}_citation_container`);
    console.log(citation_container.style.display);
    citations.forEach(hide_citation_block);
    if (citation_container.style.display === "none") {
      citation_container.style.display = "block";
    } else {
      citation_container.style.display = "none";
    }
  }
	window.addEventListener("load", function(){
	    const no_javascript_elements = document.getElementsByClassName("no-javascript");
	    const javascript_elements = document.getElementsByClassName("javascript");

	    for(let i = 0; i < no_javascript_elements.length; i++){
	        no_javascript_elements[i].remove();
	    }
	    for(let i = 0; i < javascript_elements.length; i++){
	        javascript_elements[i].style.display = "block";
	    }
	    //if(!document.getElementById("citation_section")){
	       // document.getElementById("citation-dropdown").style.display = "none";
	    //}
	})
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
