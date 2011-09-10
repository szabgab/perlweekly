 $(document).ready(function() {
   $("form.subscribe").submit(function() {
     //var url = $(this).attr('action') + '?' + $(this).serialize();
     var url = '/exe/submit.pl' + '?' + $(this).serialize();
     $.get(url, function(r) {
         window.location = "/thankyou.html";
     })
     .error(function() { alert("Sorry. Some error happened. Please let Gabor know.") });
     //$.post(url, function(r) {
     //$.post($(this).attr('action'), $(this).serialize(), function(r) {
     //   alert(r);
     //});
     return false;
   });
 });

