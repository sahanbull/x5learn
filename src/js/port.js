// Helpers and interop between Elm and JavaScript

var timeOfLastMouseMove = new Date().getTime();

var lastPageScrollOffset = 0;


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

  app.ports.openModalAnimation.subscribe(startAnimationWhenModalIsReady);

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


  app.ports.youtubeSeekTo.subscribe(function(fragmentStart) {
    player.seekTo(fragmentStart * player.getDuration());
    player.playVideo();
  });

  setupEventHandlers();

  setupScrollListener();
}


function startAnimationWhenModalIsReady(inspectorParams) {
  var modalId = inspectorParams.modalId;
  if(window.document.getElementById(modalId)==null) {
    setTimeout(function() {
      startAnimationWhenModalIsReady(inspectorParams);
    }, 15);
  }
  else{
    var card = document.activeElement;
    var modal = document.getElementById(modalId);
    card.blur(); // remove the blue outline
    app.ports.modalAnimationStart.send({frameCount: 0, start: positionAndSize(card), end: positionAndSize(modal)});
    setTimeout(function(){
      app.ports.modalAnimationStop.send(12345);
      if(inspectorParams.videoId.length>0){
        embedVideo(inspectorParams);
      }
    }, 110);
    return;
  }
}


function setupEventHandlers(){
  document.addEventListener("click", function(e){
    if(!e.target.closest('.CloseInspectorOnClickOutside')){
      app.ports.closeInspector.send(12345);
    }
    if(!e.target.closest('.ClosePopupOnClickOutside')){
      app.ports.closePopup.send(12345);
      e.stopPropagation();
    }
    app.ports.clickedOnDocument.send(12345);
  });

  document.addEventListener("mouseover", function(e){
    element = event.target;
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" ChunkTrigger ") > -1 ){
      app.ports.mouseOverChunkTrigger.send(e.pageX);
    }
  });

  document.onkeydown = function checkKey(e) {
    e = e || window.event;
    if(e.target.closest('#SearchField') || e.target.closest('#SearchSuggestions')){
      if (e.keyCode == '38') {
        changeFocusOnSearchSuggestions(-1);
      }
      else if (e.keyCode == '40') {
        changeFocusOnSearchSuggestions(1);
      }
    }
  }
}

function changeFocusOnSearchSuggestions(direction){
  var field = document.getElementById('SearchField');
  var suggestions = document.getElementById('SearchSuggestions');
  if(!suggestions){
    return
  }
  var activeElement = document.activeElement;
  var options = suggestions.childNodes[0].childNodes;
  var n = options.length;
  var index = -1;
  for(i=0;i<n; i++){
    if(options[i]==document.activeElement){
      index = i;
      break
    }
  }
  activeElement.blur();
  var newIndex = Math.max(0, Math.min(index + direction, n-1));
  options[newIndex].focus();
}


function setupScrollListener(){
  window.setInterval(function(){
    var el = document.getElementById('MainPageContent');
    if(el){
      var offset = el.scrollTop;
      if(offset!=lastPageScrollOffset){
        var contentHeight = el.childNodes[0].clientHeight;
        var scrollData = {scrollTop: el.scrollTop, viewHeight: el.clientHeight, contentHeight: contentHeight};
        app.ports.pageScrolled.send(scrollData);
        lastPageScrollOffset = offset;
      }
    }
  }, 300);
}
