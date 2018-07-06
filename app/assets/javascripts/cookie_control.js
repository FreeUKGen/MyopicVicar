$(document).ready(function() {
  // Delete Cookie
  window.delete_cookie = function(name, path, domain) {
    if (getCookie(name)) document.cookie = name + '=' +
      (('/') ? ';path=' + '/' : '') +
      (('.freereg.org.uk') ? ';domain=' + '.freereg.org.uk' : '') +
         ';expires=Thu, 01-Jan-1970 00:00:01 GMT';
  }

  // Switch Cookie checkbox value
  var toggleCookieCheckbox = function() {
    if (getCookie('userAcceptance') == 1) {
      $('#cookie_check_box').prop('checked', true);
    } else {
      $('#cookie_check_box').prop('checked', false);
    };
  };

  // Switch Adsense checkbox value
  var toggleAdsenseCheckbox = function() {
    if (getCookie('userAdPersonalization') == 1) {
      $('.adsense_check_box').prop('checked', true);
    } else {
      $('.adsense_check_box').prop('checked', false);
    };
  };

  // Create userAcceptance cookie if not exists
  var createUserAcceptance = function() {
    if ((getCookie('cookiesDirective') === null) || (getCookie('cookiesDirective') == 0)) {
      delete_cookie('cookiesDirective');
      setCookie('cookiesDirective', 1, 365);
    };

    if ((getCookie('userAcceptance') === null) || (getCookie('userAcceptance') == 'unknown') && (getCookie('userAdPersonalization') === null) || (getCookie('userAdPersonalization') == 'unknown')){
      setCookie('userAcceptance', 'unknown', 365);
      setCookie('userAdPersonalization', 'unknown', 365);
      update_third_party_cookies_user_preference('deny');
      $('.cookieConsent').slideDown('3000');
    } else {
      $('.cookieConsent').remove();
    };
  };

  // Accept Analytics Cookie
  var acceptCookie = function() {
    if ((getCookie('userAcceptance') == 0) || (getCookie('userAcceptance') == 'unknown')) {
      delete_cookie('userAcceptance');
      update_third_party_cookies_user_preference('accept');
      setCookie('userAcceptance', 1, 365);
      location.reload();
    };
  }

  // Deny  Analytics Cookie
  var denyCookie = function() {
    if (getCookie('userAcceptance') == 1) {
      delete_cookie('userAcceptance');
      update_third_party_cookies_user_preference('deny');
      setCookie('userAcceptance', 0, 365);
      location.reload();
    } else {
      setCookie('userAcceptance', 0, 365);
    };
  }

  // Accept Personalized Adverts
  var acceptPersonalizedAds = function() {
    if ((getCookie('userAdPersonalization') == 0) || (getCookie('userAdPersonalization') == 'unknown')) {
      delete_cookie('userAdPersonalization');
      setCookie('userAdPersonalization', 1, 365);
      location.reload();
    };
  }
  
  // Deny Personalized Adverts
  var denyPersonalizedAds = function() {
    if (getCookie('userAdPersonalization') == 1) {
      delete_cookie('userAdPersonalization');
      setCookie('userAdPersonalization', 0, 365);
      location.reload();
    } else {
      setCookie('userAdPersonalization', 0, 365);
    };
  }

  // Close the CookieConsent div if user accepts the policy
  createUserAcceptance();
  toggleCookieCheckbox();
  toggleAdsenseCheckbox();
//Default Deny analytics cookies
 if ((getCookie('userAcceptance') === null) || (getCookie('userAcceptance') == 'unknown')) {
     setCookie('userAcceptance', 'unknown', 365 );
     update_third_party_cookies_user_preference('deny');
   };
// Accept Analytic Cookie
  if (getCookie('userAcceptance') == 1) {
     update_third_party_cookies_user_preference('accept');
   };
//Deny analytics cookies
  if (getCookie('userAcceptance') == 0) {
     update_third_party_cookies_user_preference('deny');
   };

  $('.cookie_check_box').change(function() {
    if($(this).is(":checked")) {
      acceptCookie();
    } else {
      denyCookie();
    };
  });

  $('.adsense_check_box').change(function() {
  if($(this).is(":checked")) {
      acceptPersonalizedAds();
    } else {
      denyPersonalizedAds();
    };
  });

  $('.accept_cookies').click(function() {
    acceptCookie();
    acceptPersonalizedAds();
  });

  $('#cookie_policy').click(function() {
    setCookie('userAcceptance', 0, 365);
    setCookie('userAdPersonalization', 0, 365);
    $('.cookieConsent').remove();
  });
});
