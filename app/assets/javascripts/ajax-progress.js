
// AJAX Form Submit
  $(".submit").on("change",
    function(event) {

      // Show Progress Indicator
      $(".ajax-progress").show();

      ...

      $(this).closest("tr").find("form").submit();

    });
// END



