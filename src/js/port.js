// Helpers and interop between Elm and JavaScript

var timeOfLastMouseMove = new Date().getTime();


function positionAndSize(el) {
  var rect = el.getBoundingClientRect(), scrollLeft = window.pageXOffset || document.documentElement.scrollLeft, scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  return { x: rect.left + scrollLeft, y: rect.top + scrollTop, sx: el.offsetWidth, sy: el.offsetHeight }
}


function position(el) {
  ps = positionAndSize(el);
  return { x: ps.x, y: ps.y }
}


function setupPorts(app){
  // app.ports.copyClipboard.subscribe(function(dummy) {
  //   document.querySelector('#ClipboardCopyTarget').select();
  //   document.execCommand('copy');
  // });

  app.ports.openModalAnimation.subscribe(function(modalId) {
    startAnimationWhenModalIsReady(modalId)
  });

  app.ports.setBrowserFocus.subscribe(function(elementId) {
    document.activeElement.blur();
    if(elementId != ""){
      setTimeout(function(){
        try{
          document.getElementById(elementId).focus();
        } catch(err){
          // ignore
        }
      }, 30);
    }
  });

  setupClickHandlers();
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


function setupClickHandlers(){
  document.addEventListener("click", function(e){
    if(!e.target.closest('.InspectorAutoclose')){
      app.ports.closeInspector.send(12345);
    }
    app.ports.clickedOnDocument.send(12345);
  });
  document.addEventListener("mousemove", function(e){
    now = new Date().getTime();
    if(now-timeOfLastMouseMove > 200){//no need to notify Elm of every mouse event. Only transmit the beginning of gestures.
      app.ports.mouseMoved.send(12345);
    }
    timeOfLastMouseMove = now;
  });
}
