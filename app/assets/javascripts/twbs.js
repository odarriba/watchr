// Functions to enable tooltip and popover functionality
(function() {
  jQuery(function() {
    $("[data-toggle='tooltip']").tooltip();
    $("[data-toggle='popover']").popover();

    return true;
  });

}).call(this);
