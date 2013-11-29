/* jshint -W098 */

/*
 * Chained - jQuery / Zepto chained selects plugin
 *
 * Copyright (c) 2010-2013 Mika Tuupola
 *
 * Licensed under the MIT license:
 *   http://www.opensource.org/licenses/mit-license.php
 *
 * Project home:
 *   http://www.appelsiini.net/projects/chained
 *
 * Version: 0.9.8
 *
 */
/* BWB changed to handle multi-selects */
;(function($, window, document, undefined) {
    "use strict";

    $.fn.chained = function(parent_selector, options) {

        var settings = $.extend( {}, $.fn.chained.defaults, options);

        return this.each(function() {

            /* Save this to self because this changes when scope changes. */
            var self   = this;
            var backup = $(self).clone();

            /* Handles maximum two parents now. */
            $(parent_selector).each(function() {

                $(this).bind("change", function() {
                    $(self).html(backup.html());

                    /* If multiple parents build classname like foo\bar. */
                    var selected = [];
                    $(parent_selector).each(function() {
                        $(":selected", this).each(function() {
                            selected.push($(this).val());
                        });
                    });

                    /* Also check for first parent without subclassing. */
                    /* TODO: This should be dynamic and check for each parent */
                    /*       without subclassing. */
                    var first;
                    if ($.isArray(parent_selector)) {
                        first = $(parent_selector[0]).first();
                    } else {
                        first = $(parent_selector).first();
                    }
                    var selected_first = $(":selected", first).val();

                    $("option", self).each(function() {


                    	var hasSelectedClass = false;
                    	var classList = ($(this).attr('class') == undefined || "" ) ? [] : $(this).attr('class').split(/\s+/);
                    	$.each( classList, function(index, item){
	                    	if (jQuery.inArray(item, selected) >= 0) {
		                    	hasSelectedClass = true;
		                    	return;
	                    	}
                    	});
                    	if (!hasSelectedClass &&
	                    	!$(this).hasClass(selected_first) && $(this).val() !== "") {
	                    	$(this).remove();
                    	}
                    	
                    });

                    /* If we have only the default value disable select. */
                    if (1 === $("option", self).size() && $(self).val() === "") {
                        $(self).attr("disabled", "disabled");
                    } else {
                        $(self).removeAttr("disabled");
                    }
                    $(self).trigger("change");
                });

                /* Force IE to see something selected on first page load, */
                /* unless something is already selected */
                if (!$("option:selected", this).length) {
                    $("option", this).first().attr("selected", "selected");
                }

                /* Force updating the children. */
                $(this).trigger("change");

            });
        });
    };

    /* Alias for those who like to use more English like syntax. */
    $.fn.chainedTo = $.fn.chained;

    /* Default settings for plugin. */
    $.fn.chained.defaults = {};

})(window.jQuery || window.Zepto, window, document);