$(document).ready(function() { 
  if ( $( ".cen_unit" ).length ) {
  //Default set Non personalized Adverts
    if ((getCookie('userAdPersonalization') === null) || (getCookie('userAdPersonalization') == 'unknown')) {
      setCookie('userAdPersonalization', 'unknown', 365 );
      if ( $( ".cen_unit_header" ).length ) {
        //update_personalized_page_adverts('deny');
        update_personalized_header_adverts('deny');
      };
      if ( $( ".cen_unit_page" ).length ) {
        update_personalized_adverts('deny');
      };
      if ( $( ".cen_unit_fullwidth" ).length ) {
        update_personalized_fullwidth_adverts('deny');
      };
     };
  // Personalized Advert
    if (getCookie('userAdPersonalization') == 1) {
       //update_personalized_google_adverts('accept');
      if ( $( ".cen_unit_header" ).length ) {
        //update_personalized_page_adverts('accept');
        update_personalized_header_adverts('accept');
      };
      if ( $( ".cen_unit_page" ).length ) {
        update_personalized_adverts('accept');
      };
      if ( $( ".cen_unit_fullwidth" ).length ) {
        update_personalized_fullwidth_adverts('accept');
      };
     };
  //Non Personalized Advert
    if (getCookie('userAdPersonalization') == 0) {
       //update_personalized_google_adverts('deny');
      if ( $( ".cen_unit_header" ).length ) {
        //update_personalized_page_adverts('deny');
        update_personalized_header_adverts('deny');
      };
      if ( $( ".cen_unit_page" ).length ) {
        update_personalized_adverts('deny');
      };
      if ( $( ".cen_unit_fullwidth" ).length ) {
        update_personalized_fullwidth_adverts('deny');
      };
    };
  };

$(document).ready(function() {
  if ( $( ".reg_adsense" ).length ) {

  //Default set Non personalized Adverts
    if ((getCookie('userAdPersonalization') === null) || (getCookie('userAdPersonalization') == 'unknown')) {
       setCookie('userAdPersonalization', 'unknown', 365 );
       update_personalized_google_adverts('deny');
     };
  // Personalized Advert
    if (getCookie('userAdPersonalization') == 1) {
       update_personalized_google_adverts('accept');
     };
  //Non Personalized Advert
    if (getCookie('userAdPersonalization') == 0) {
       update_personalized_google_adverts('deny');
    };
  };
});