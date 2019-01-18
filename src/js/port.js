// Helpers and interop between Elm and JavaScript


function positionAndSize(el) {
  var rect = el.getBoundingClientRect(),
  scrollLeft = window.pageXOffset || document.documentElement.scrollLeft,
  scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  return { posX: rect.top + scrollTop, posY: rect.left + scrollLeft, sizeX: el.offsetWidth, sizeY: el.offsetHeight }
}


function setupPorts(app){
  // app.ports.copyClipboard.subscribe(function(dummy) {
  //   document.querySelector('#ClipboardCopyTarget').select();
  //   document.execCommand('copy');
  // });

  app.ports.inspectSearchResult.subscribe(function(modalId) {
    console.log('inspectSearchResult');
    setTimeout(function(){
      var card = document.activeElement;
      var modal = document.getElementById(modalId);
      app.ports.modalAnim.send({card: positionAndSize(card), modal: positionAndSize(modal)})
      // console.log(pos);
      // console.log(positionAndSize(modal));
    }, 300);
  });
}
