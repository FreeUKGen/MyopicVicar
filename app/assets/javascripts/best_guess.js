$(document).ready(function() {
	document.getElementById("citation-toggle").addEventListener("click", citationToggle);
	/*Hide citation blocks unless citation type is selected*/
	 const citations = ['wikitree_inline', 'wikitree_ref', 'familytree', 'evidence_explained', 'wikipedia'];
	function hide_citation_block(cite){
	  cite_element =  document.getElementById(`${cite}_citation_container`);
	  if (cite_element) {
	    cite_element.style.display = "none";
	  }
	}
	/* When the user clicks on the button,
	toggle between hiding and showing the dropdown content */
	function citationToggle() {
	  var x = document.getElementById("citation-dropdown");
	  //var y = document.getElementById('wikitree_citation_container');
	  citations.forEach(hide_citation_block);
	  if (x.style.display === "none") {
	    x.style.display = "block";
	  } else {
	    x.style.display = "none";
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
	        document.getElementById("citation-dropdown").style.display = "none";
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
