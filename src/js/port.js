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
    startAnimationWhenModalIsReady(modalId, 100)
  });
  app.ports.determinePopupPosition.subscribe(function(popupTriggerId) {
    determinePopupPosition(popupTriggerId, 100)
  });
}


function startAnimationWhenModalIsReady(modalId, attempts) {
  if(attempts<1) {
    return
  }
  if(window.document.getElementById(modalId)==null) {
    setTimeout(function() {
      startAnimationWhenModalIsReady(modalId, attempts-1);
    }, 15);
  } else{
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

function determinePopupPosition(popupTriggerId, attempts) {
  if(attempts<1) {
    return
  }
  var trigger = window.document.getElementById(popupTriggerId)
  if(trigger==null) {
    setTimeout(function() {
      determinePopupPosition(popupTriggerId, attempts-1);
    }, 15);
  } else{
    var rect = positionAndSize(trigger);
    app.ports.setPopupPosition.send({x: rect.x, y: rect.y + 17});
  }
}
