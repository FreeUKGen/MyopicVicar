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
/*
  // Switch Cookie checkbox value
  var toggleCookieCheckbox = function() {
    if (getCookie('userAcceptance') == 1) {
      $('#cookie_check_box').prop('checked', true);
    } else {
      $('#cookie_check_box').prop('checked', false);
    };
  };
*/
  /*donate cta 
  window.setBigGiveCookie = function(name,value) {
    var expires = "";
    var date = new Date();
    expirationDate = new Date(date.getFullYear(), date.getMonth(), date.getDate()+1, 0, 0, 0);
    expires = "; expires="+expirationDate.toGMTString();
    document.cookie = name+"="+value+expires+"; path=/";
  };

  var close_donate_cta = function(){
    //setCookie('donate_cta_flag_new', 1,1);
    setBigGiveCookie('donate_cta_flag_new', 1);//big gift code change
    document.getElementById("myDialog").close(); 
      $("#donate_cta_pop_up").hide();
      document.getElementById("overlay").style.display = "none";

  };

  if ((getCookie('donate_cta_flag_new') == 0) || (getCookie('donate_cta_flag_new') === null)) {
    var dialog = document.getElementById("myDialog");
    var overlay = document.getElementById("overlay");
    var close_cta = document.getElementById('close_donate_cta_pop_up');
    var donate_now = document.getElementById('donate_now_button');
    var read_more = document.getElementById('read_more');
    if(!(dialog?.open)){
      dialog?.showModal();
    }
    if (overlay?.length) {
      overlay.style.display = "block";
    }
    $("#donate_cta_pop_up").show();
    close_cta ? close_cta.onclick = close_donate_cta : 'undefined';
    donate_now ? donate_now.onclick = close_donate_cta : 'undefined';
    read_more ? read_more.onclick = close_donate_cta : 'undefined';
  }

//close overlay with esc key
$(document).keyup(function(evt) {
  evt = evt || window.event;
  var isEscape = false;
  if ("key" in evt) {
      isEscape = (evt.key === "Escape" || evt.key === "Esc");
  } else {
      isEscape = (evt.keyCode === 27);
  }
  console.log(isEscape);
  if (isEscape) {
      close_donate_cta();
  }  // esc
});

/*document.getElementById('reminder_form_controller').onclick = function show_remind_me_later_form() {
  setCookie('donate_cta_flag_new', 1,1);
  document.getElementById("myDialog").close();
  document.getElementById("myDialog1").showModal();
  $("#donate_cta_pop_up").hide();
  $("#reminder_form_controller").hide();
  var element = document.getElementById("donate_box");
  var elem = document.getElementById("other_links")
  element.className = "grid__item desk-one-half lap-one-half palm-one-whole";
  element.classList.remove('text--center');
  elem.classList.remove('text--center');
  elem.className = "float--right";
}
/*CTA code changes ends */
/*
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
  */
});
