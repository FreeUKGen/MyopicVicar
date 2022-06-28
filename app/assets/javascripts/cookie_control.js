$(document).ready(function() {
  var app_name = window.location.hostname;
  // Delete Cookie
  window.delete_cookie = function(name, path, domain) {
    if (getCookie(name)) {
      document.cookie = name + '=' +
      (('/') ? ';path=' + '/' : '') +
      ((app_name) ? ';domain=' + app_name : '') +
         ';expires=Thu, 01-Jan-1970 00:00:01 GMT';
    }
  };

  // Switch Cookie checkbox value
  var toggleCookieCheckbox = function() {
    if (getCookie('userAcceptance') == 1) {
      $('#cookie_check_box').prop('checked', true);
    } else {
      $('#cookie_check_box').prop('checked', false);
    };
  };

  //turn off donate cta
var close_donate_cta = function(){
  setCookie('donate_cta_flag', 1,365);
  document.getElementById("myDialog").close(); 
    $("#donate_cta_pop_up").hide();
    document.getElementById("overlay").style.display = "none";

};

  if ((getCookie('donate_cta_flag') == 0) || (getCookie('donate_cta_flag') === null)) {
    document.getElementById("myDialog").showModal(); 
  document.getElementById("overlay").style.display = "block";
  $("#donate_cta_pop_up").show();
  document.getElementById('close_donate_cta_pop_up').onclick = close_donate_cta;
  document.getElementById('donate_now_button').onclick = close_donate_cta;
  document.getElementById('read_more').onclick = close_donate_cta;
}

document.getElementById('reminder_form_controller').onclick = function show_remind_me_later_form() {
  setCookie('donate_cta_flag', 1,365);
  document.getElementById("myDialog").close();
  document.getElementById("myDialog1").showModal();
  $("#reminder_to_donate_form").show();
  $("#donate_cta_pop_up").hide();
  $("#reminder_form_controller").hide();
  var element = document.getElementById("donate_box");
  var elem = document.getElementById("other_links")
  element.className = "grid__item desk-one-half lap-one-half palm-one-whole";
  element.classList.remove('text--center');
  elem.classList.remove('text--center');
  elem.className = "float--right";
}

document.getElementById('donate_cta_feedback').onclick = function show_feedback_form() {
  setCookie('donate_cta_flag', 1,365);
  document.getElementById("myDialog").close();
  document.getElementById("myDialog2").showModal();
  $("#donate_cta_feedback_form").show();
  $("#donate_cta_pops").hide();
}


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
      //update_third_party_cookies_user_preference('deny');
      $('.cookieConsent').slideDown();
    } else {
      $('.cookieConsent').remove();
    };
  };

  // Accept Analytics Cookie
  var acceptCookie = function() {
    if ((getCookie('userAcceptance') == 0) || (getCookie('userAcceptance') == 'unknown')) {
      delete_cookie('userAcceptance');
      //update_third_party_cookies_user_preference('accept');
      setCookie('userAcceptance', 1, 365);
      location.reload();
    };
  }

  // Deny  Analytics Cookie
  var denyCookie = function() {
    if (getCookie('userAcceptance') == 1) {
      delete_cookie('userAcceptance');
      //update_third_party_cookies_user_preference('deny');
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
     update_analytics('deny');
   };
// Accept Analytic Cookie
  if (getCookie('userAcceptance') == 1) {
     update_analytics('accept');
   };
//Deny analytics cookies
  if (getCookie('userAcceptance') == 0) {
    update_analytics('deny');
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
