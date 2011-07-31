 $(document).ready(function() {
   $("form.subscribe").submit(function() {
     var url = $(this).attr('action') + '?' + $(this).serialize();
     $.get(url, function(r) {
         window.location = "/thankyou.html";
     });
     //$.post(url, function(r) {
     //$.post($(this).attr('action'), $(this).serialize(), function(r) {
     //   alert(r);
     //});
     return false;
   });
 });

