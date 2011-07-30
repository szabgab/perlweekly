 $(document).ready(function() {
   $("form.subscribe").submit(function() {
     //alert( $(this).attr('action') );
     //alert( $(this).serialize() );
     var url = $(this).attr('action') + '?' + $(this).serialize();
//alert(url);
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

