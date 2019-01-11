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