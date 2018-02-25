function deleteTicket(uuid) {
  var url = '/tickets/' + uuid;
  if(confirm("Delete ticket and all content?")){
  fetch(url,
      {
        method: 'delete',
        credentials: 'same-origin'
      }).then(function(response){
    $("#"+uuid).remove();
  }, function(error){
        alert(error);
  });
  }
};

function uploadFile(uuid, fn) {
  var url = '/tickets/' + uuid + '/upload/' + fn;
  fetch(url,
      {
        method: 'put',
        credentials: 'same-origin'
      }).then(function(response){
    alert('uploading')
  }, function(error){
        alert(error);
  });
};

function toggleUploads(uuid) {
  var btn = document.getElementById("uploadswitch-"+uuid );
  var state = btn.checked
  var url = '/tickets/' + uuid + '/allow_uploads?allow_uploads='+state;
  fetch(url,
      {
        method: 'PATCH',
        credentials: 'same-origin',
        body: 'allow_uploads:'+state
      }).then(function(response){
  }, function(error){
        console.log(error);
  });
};
