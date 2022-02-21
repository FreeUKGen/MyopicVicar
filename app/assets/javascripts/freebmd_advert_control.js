$(document).ready(function() {
  var app_name = window.location.hostname;
  // advert control for freereg application
    //Default set Non personalized Adverts
  if ((getCookie('userAdPersonalization') === null) || (getCookie('userAdPersonalization') == 'unknown')) {
    setCookie('userAdPersonalization', 'unknown', 365 );
      //update_personalized_page_adverts('deny');
      update_personalized_adverts('deny');
   };
// Personalized Advert
  if (getCookie('userAdPersonalization') == 1) {
     //update_personalized_google_adverts('accept');
      //update_personalized_page_adverts('accept');
      update_personalized_adverts('accept');
   };
//Non Personalized Advert
  if (getCookie('userAdPersonalization') == 0) {
     //update_personalized_google_adverts('deny');
   
      //update_personalized_page_adverts('deny');
      update_personalized_adverts('deny');
  };
});