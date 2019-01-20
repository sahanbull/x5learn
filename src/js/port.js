// Helpers and interop between Elm and JavaScript


function positionAndSize(el) {
  var rect = el.getBoundingClientRect(),
  scrollLeft = window.pageXOffset || document.documentElement.scrollLeft,
  scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  return { x: rect.left + scrollLeft, y: rect.top + scrollTop, sx: el.offsetWidth, sy: el.offsetHeight }
}


function setupPorts(app){
  // app.ports.copyClipboard.subscribe(function(dummy) {
  //   document.querySelector('#ClipboardCopyTarget').select();
  //   document.execCommand('copy');
  // });

  app.ports.openModalAnimation.subscribe(function(modalId) {
    startAnimationWhenModalIsReady(modalId)
  });
}


function startAnimationWhenModalIsReady(modalId) {
  if(window.document.getElementById(modalId)==null) {
    setTimeout(function() {
      startAnimationWhenModalIsReady(modalId);
    }, 15);
  }
  else{
    var card = document.activeElement;
    var modal = document.getElementById(modalId);
    card.blur(); // remove the blue outline
    app.ports.modalAnimationStart.send({frameCount: 0, start: positionAndSize(card), end: positionAndSize(modal)});
    setTimeout(function(){
      app.ports.modalAnimationStop.send(12345);
    }, 110);
    return;
  }
}
