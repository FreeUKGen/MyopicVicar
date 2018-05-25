$(document).ready(function() {

  // Delete Cookie
  window.delete_cookie = function(name) {
    if (getCookie(name)) document.cookie = name + '=' +
        (('/') ? ';path=' + '/' : '') +
        (('.freecen.org.uk') ? ';domain=' + '.freecen.org.uk' : '') +
        ';expires=Thu, 01-Jan-1970 00:00:01 GMT';
  }

  // Create userAcceptance cookie if not exists
  var createUserAcceptance = function() {
    if ((getCookie('cookiesDirective') === null) || (getCookie('cookiesDirective') == '0')) {
      delete_cookie('cookiesDirective');
      setCookie('cookiesDirective', 1, 365);
    };

    if (getCookie('userAcceptance') === null) {
      setCookie('userAcceptance', 0, 365);
      update_third_party_cookies_user_preference('deny');
    } else if (getCookie('userAcceptance') == 1) {
      $('.cookieConsent').remove();
    };
  };

  // Accept Cookie
  var acceptCookie = function() {
    if (getCookie('userAcceptance') == 0) {
      delete_cookie('userAcceptance');
      update_third_party_cookies_user_preference('accept');
      setCookie('userAcceptance', 1, 365);
      location.reload();
      $('.cookieConsent').remove();
    } else {
      alert('Thank you. You have already accepted the cookie policy.');
    };
  }

  // Deny Cookie
  var denyCookie = function() {
    if (getCookie('userAcceptance') == 1) {
      delete_cookie('userAcceptance');
      update_third_party_cookies_user_preference('deny');
      setCookie('userAcceptance', 0, 365);
      location.reload();
      $('.cookieConsent').slideDown();
    } else {
      alert('Thank you. You have already Declined the cookie policy.');
    };
  }

  // Close the CookieConsent div at the top
  $('#CloseCookieConsent').click(function() {
    $('.cookieConsent').slideUp();
  });

  // Close the CookieConsent div if user accepts the policy

  createUserAcceptance();
  $('.accept_cookies').click(function() {
    acceptCookie();
  });
  $('#deny_cookies').click(function() {
    denyCookie();
  });

});
