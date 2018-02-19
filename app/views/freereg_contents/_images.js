var tbody = document.getElementById('show_detail');
var tbody_childs = tbody.childNodes;

for (i=0; i<tbody_childs.length; i++) {
	if (tbody_childs[i].nodeType == 1) {
		var tr_childs = tbody_childs[i].childNodes;

		for (j=0; j<tr_childs.length; j++) {
			if (tr_childs[j].id == 'progress_detail' || tr_childs[j].id == 'available_detail') {
				tr_childs[j].addEventListener("click", onCellClicked, false);
			}
		}
	}
}

function onCellClicked(e) {
	var first_tr = this.parentNode;
	var second_tr = first_tr.nextElementSibling;
	var third_tr = second_tr.nextElementSibling;

	var second_childs = second_tr.childNodes;
	for (i=0; i<second_childs.length; i++) {
		if (second_childs[i].nodeType == 1) {
			if (second_childs[i].style.display == 'none') {
				second_childs[i].style.display = 'table-cell';
			} else {
				second_childs[i].style.display = 'none';
			}
		}
	}

	var third_childs = third_tr.childNodes;
	for (i=0; i<third_childs.length; i++) {
		if (third_childs[i].nodeType == 1) {
			if (third_childs[i].style.display == 'none') {
				third_childs[i].style.display = 'table-cell';
			} else {
				third_childs[i].style.display = 'none';
			}
		}
	}
}
