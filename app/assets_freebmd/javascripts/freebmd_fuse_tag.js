// Loaded only when DonationCampaign is active (FreeBMD) — mirrors the Publift block removed from <head>.
// Keeps fusetag queue + pageInit in sync with the async fuse.js load.
(function () {
  var fusetag = window.fusetag || (window.fusetag = { que: [] });

  fusetag.que.push(function () {
    fusetag.pageInit({
      pageTargets: [
        {
          key: 'freebmd_site',
          value: 'beta',
        },
      ],
    });
  });

  var s = document.createElement('script');
  s.async = true;
  s.src = 'https://cdn.fuseplatform.net/publift/tags/2/4135/fuse.js';
  (document.head || document.getElementsByTagName('head')[0]).appendChild(s);
})();
