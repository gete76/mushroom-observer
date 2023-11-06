/**
 * This should be included on every page.
 */

$(document).on("ready turbo:load", function () {

  // This works better than straight autofocus attribute in firefox.
  // Normal autofocus causes it to scroll window hiding title etc.
  jQuery('[data-autofocus=true]').first().focus();

  jQuery('[data-role=link]').on('click', function () {
    window.location = jQuery(this).attr('data-url');
  });

  jQuery('[data-toggle="tooltip"]').tooltip({ container: 'body' });

  // HAMBURGER HELPER
  jQuery('[data-toggle="offcanvas"]').on('click', function () {
    jQuery(document).scrollTop(0);
    jQuery('.row-offcanvas').toggleClass('active');
    jQuery('#main_container').toggleClass('hidden-overflow-x');

  });

  // SEARCH BAR FINDER
  jQuery('[data-toggle="search"]').on('click', function () {
    jQuery(document).scrollTop(0);
    var target = jQuery(this).data().target;
    // jQuery(target).css('margin-top', '32px');
    jQuery(target).toggleClass('hidden-xs');
  });

  jQuery('[data-dismiss="alert"]').on('click', function () {
    setCookie('hideBanner2', BANNER_TIME, 30);
  });

  function setCookie(cname, cvalue, exdays) {
    var d = new Date();
    d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
    var expires = "expires=" + d.toUTCString();
    document.cookie = cname + "=" + cvalue + "; " + expires
      + ";samesite=lax;path=/";
  }

  jQuery('.file-field :file').on('change', function () {
    var val = $(this).val().replace(/.*[\/\\]/, ''),
      next = $(this).parent().next();
    // If file field immediately followed by span, show selection there.
    if (next.is('span')) next.html(val);
  });

  // Not a great solution, but ok for now.
  jQuery('form :input').on('change', function () {
    var disabled_buttons = $('[data-disable-with]');
    $(disabled_buttons).each(function () {
      $.rails.enableElement(this);
    })
  });

  // very precise binding for dynamically generated lightbox links
  // they are not there on page load, only when lightbox activated
  jQuery('body').on('click', '#lightbox .lb-dataContainer button.lightbox_link', function (e) {
    e.stopPropagation();
    var button = jQuery(e.target),
      modal_target_id = button.data("target");
    // must pass the button itself as second param
    jQuery(modal_target_id).modal("toggle", button);
  });

  // Initialize Verlok LazyLoad
  var lazyLoadInstance = new LazyLoad({
    elements_selector: ".lazy"
    // ... more custom settings?
  });

  // Update lazy loads
  lazyLoadInstance.update();
});

// This is the callback for when the google maps api script is loaded (async,
// from Google) on the Create Obs form, and potentially elsewhere.
// It dispatches a global event that can be picked up by MOObservationMapper,
// or a potential Stimulus controller doing the same thing. The mapper needs to
// know when the script is loaded, because its methods will not work otherwise.
window.dispatchMapsEvent = function (...args) {
  const gmaps_loaded = new CustomEvent("google-maps-loaded", {
    bubbles: true,
    detail: args
  })
  console.log("maps is loaded")
  window.dispatchEvent(gmaps_loaded)
}

// This observer is a stopgap that handles what Stimulus would handle:
// observes page changes and whether they should fire js.
function moObserveContent() {
  // Select the node that will be observed for mutations
  const contentNode = document.body;

  // Options for the observer (which mutations to observe)
  const config = { attributes: true, childList: true, subtree: true };

  // Callback function to execute when mutations are observed
  const callback = (mutationList, observer) => {
    for (const mutation of mutationList) {
      if (mutation.type === "childList") {
        // console.log("A child node has been added or removed.");
        // initializeAutocompleters();
        initializeObservationMapper();
      } else if (mutation.type === "attributes") {
        // console.log(`The ${mutation.attributeName} attribute was modified.`);
      }
    }
  };

  // Create an observer instance linked to the callback function
  const observer = new MutationObserver(callback);

  // Start observing the target node for configured mutations
  observer.observe(contentNode, config);

  // Don't do anything unless there's a form and class has not been initialized
  // Plus, because this class is not yet a Stimulus controller, it should not
  // initialize until google maps api is loaded. The observer will keep checkin'
  const initializeObservationMapper = function () {
    if (document.getElementById("observation_form") &&
      (typeof window.observationMapper == 'undefined') &&
      (typeof MOObservationMapper != 'undefined') &&
      (typeof (google) != "undefined")) {
      // there's only going to be one in the window
      window.observationMapper = new MOObservationMapper();
    }
  }
}

moObserveContent();
