$(document).ready(function() {
  // advert control for freereg application
  if ( $( ".reg_unit" ).length ) {
  //Default set Non personalized Adverts
    if ((getCookie('userAdPersonalization') === null) || (getCookie('userAdPersonalization') == 'unknown')) {
      setCookie('userAdPersonalization', 'unknown', 365 );
      update_personalized_adverts('deny');
      if ( $( ".reg_page_level_ads" ).length ) {
        update_page_level_adverts_consent('deny');
      };
     };
  // Personalized Advert
    if (getCookie('userAdPersonalization') == 1) {
    	update_personalized_adverts('accept');
      if ( $( ".reg_page_level_ads" ).length ) {
        update_page_level_adverts_consent('accept');
      };
     };
  //Non Personalized Advert
    if (getCookie('userAdPersonalization') == 0) {
       update_personalized_adverts('deny');
      if ( $( ".reg_page_level_ads" ).length ) {
        update_page_level_adverts_consent('deny');
      };
    };
  };
});