// Helpers and interop between Elm and JavaScript

var timeOfLastMouseMove = new Date().getTime();

var lastPageScrollOffset = 0;

var videoEventThrottlePosition = 0; // Limit the frequency of events sent to Elm
var isVideoPlaying = false;
var videoPlayPosition = 0;

// Number of seconds between actions that report the ongoing video play position.
// Keep this constant in sync with videoPlayReportingInterval in Elm
// and VIDEO_PLAY_REPORTING_INTERVAL in python
var videoPlayReportingInterval = 10;


function positionAndSize(el) {
  var rect = el.getBoundingClientRect(), scrollLeft = window.pageXOffset || document.documentElement.scrollLeft, scrollTop = window.pageYOffset || document.documentElement.scrollTop;
  return { x: rect.left + scrollLeft, y: rect.top + scrollTop, sx: el.offsetWidth, sy: el.offsetHeight }
}


function position(el) {
  ps = positionAndSize(el);
  return { x: ps.x, y: ps.y }
}


function setupPorts(app){
  app.ports.openModalAnimation.subscribe(startAnimationWhenModalIsReady);
  // app.ports.embedYoutubePlayerOnResourcePage.subscribe(embedYoutubePlayerOnResourcePage);

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

  app.ports.getOerCardPlaceholderPositions.subscribe(function(dummy) {
    setTimeout(function(){
      var placeholders = document.getElementsByClassName('OerCardPlaceholder');
      positions = [].slice.call(placeholders).map(getCardPlaceholderPosition);
      app.ports.receiveCardPlaceholderPositions.send(positions);
    }, 100);
  });

  app.ports.askPageScrollState.subscribe(function(dummy) {
    setTimeout(function(){
      sendPageScrollState(true);
    }, 100);
  });

  app.ports.startCurrentHtml5Video.subscribe(function(position) {
    var vid = getHtml5VideoPlayer();
    if(vid){
      playWhenPossible(vid, position);
    }
  });

  // app.ports.youtubeSeekTo.subscribe(function(fragmentStart) {
  //   player.seekTo(fragmentStart * player.getDuration());
  //   player.playVideo();
  // });

  // app.ports.youtubeDestroyPlayer.subscribe(function(dummy) {
  //   if(typeof player !== 'undefined' && player.getIframe()!==null){
  //     player.destroy();
  //   }
  // });

  setupEventHandlers();

  setupScrollDetector();
}


function sendPageScrollState(requestedByElm){
  var el = document.getElementById('MainPageContent');
  if(el){
    var offset = el.pageYOffset !== undefined ? el.pageYOffset : el.scrollTop;
    if(requestedByElm || offset!=lastPageScrollOffset){
      var contentHeight = el.childNodes[0].clientHeight;
      var pageScrollState = {scrollTop: el.scrollTop, viewHeight: el.clientHeight, contentHeight: contentHeight, requestedByElm: requestedByElm};
      app.ports.pageScrolled.send(pageScrollState);
      lastPageScrollOffset = offset;
    }
  }
}


function startAnimationWhenModalIsReady(videoEmbedParams) {
  var modalId = videoEmbedParams.modalId;
  if(window.document.getElementById(modalId)==null) {
    setTimeout(function() {
      startAnimationWhenModalIsReady(videoEmbedParams);
    }, 15);
  }
  else{
    var card = document.activeElement;
    var modal = document.getElementById(modalId);
    card.blur(); // remove the blue outline
    app.ports.modalAnimationStart.send({frameCount: 0, start: positionAndSize(card), end: positionAndSize(modal)});
    setTimeout(function(){
      app.ports.modalAnimationStop.send(12345);
      if(videoEmbedParams.videoId.length>0){
        embedYoutubeVideo(videoEmbedParams);
      }else{
        var vid = getHtml5VideoPlayer();
        if(vid){
          if(videoEmbedParams.playWhenReady){
            playWhenPossible(vid, videoEmbedParams.videoStartPosition);
          }

          vid.onplay = function() {
            isVideoPlaying = true;
            videoPlayPosition = vid.currentTime;
            app.ports.html5VideoStarted.send(videoPlayPosition);
            videoEventThrottlePosition = videoPlayPosition;
          };
          vid.onpause = function() {
            isVideoPlaying = false;
            videoPlayPosition = vid.currentTime;
            app.ports.html5VideoPaused.send(videoPlayPosition);
          };
          vid.ontimeupdate = function() {
            videoPlayPosition = vid.currentTime;
            if(isVideoPlaying){
              if(videoPlayPosition > videoEventThrottlePosition + videoPlayReportingInterval){
                app.ports.html5VideoStillPlaying.send(videoPlayPosition);
                videoEventThrottlePosition = videoPlayPosition;
              }
            }else{
              app.ports.html5VideoSeeked.send(videoPlayPosition);
              videoEventThrottlePosition = 0;
            }
          };
        }else{
          // video not found
        }
      }
    }, 110);
    return;
  }
}


function getHtml5VideoPlayer(){
  return document.getElementById("Html5VideoPlayer");
}

// function embedYoutubePlayerOnResourcePage(videoEmbedParams) {
//     setTimeout(function(){
//       if(videoEmbedParams.videoId.length>0){
//         embedYoutubeVideo(videoEmbedParams);
//       }
//     }, 200);
// }



/* setupEventHandlers
 * Note that we add the event listeners directly to the document, i.e. at the root level.
 * Adding them to individual elements further down the tree wouldn't be wise
 * because the Elm createth and taketh them away dynamically.
 * We can use classes and e.target.closest(...) to check where an event fired from.
 */
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

  document.addEventListener("mouseover", function(event){
    var element = event.target;
    if(element.classList.contains('Heart') &! element.classList.contains('HeartFlying')){
      var eventPosition = getEventPosition(event);
      var wrapperPositionY = position(document.getElementsByClassName('HeartAnimWrapper')[0]).y;
      var hoveringHeartPosition = {x: eventPosition.x-30, y: eventPosition.y-20-wrapperPositionY};
      app.ports.receiveFlyingHeartRelativeStartPosition.send(hoveringHeartPosition);
      return
    }
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" ChunkTrigger ") > -1 ){
      app.ports.mouseOverChunkTrigger.send(event.pageX);
      return
    }
  });

  [ 'mousedown', 'mouseup', 'mousemove' ].forEach(registerTimelineMouseEvent);

  document.onkeydown = function checkKey(e) {
    e = e || window.event;
    if(e.target.closest('#SearchField') || e.target.closest('#AutocompleteSuggestions')){
      if (e.keyCode == '38') {
        changeFocusOnAutocompleteSuggestions(-1);
      }
      else if (e.keyCode == '40') {
        changeFocusOnAutocompleteSuggestions(1);
      }
    }
  }
}


function changeFocusOnAutocompleteSuggestions(direction){
  var field = document.getElementById('SearchField');
  var suggestions = document.getElementById('AutocompleteSuggestions');
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


function setupScrollDetector(){
  window.setInterval(function(){
    sendPageScrollState(false);
  }, 100);
}


function getCardPlaceholderPosition(ph){
  var rect = ph.getBoundingClientRect();
  var scrollY = document.getElementById('OerCardsContainer').getBoundingClientRect().top;
  return { x: rect.left, y: rect.top - scrollY, oerId: parseInt(ph.getAttribute("data-oerid")) };
}


function getEventPosition(event){
  // some boilerplate for browser compatibility
  // https://stackoverflow.com/questions/7790725/javascript-track-mouse-position
  var eventDoc, doc, body;
  event = event || window.event; // IE-ism
  // If pageX/Y aren't available and clientX/Y are,
  // calculate pageX/Y - logic taken from jQuery.
  // (This is to support old IE)
  if (event.pageX == null && event.clientX != null) {
    eventDoc = (event.target && event.target.ownerDocument) || document;
    doc = eventDoc.documentElement;
    body = eventDoc.body;

    event.pageX = event.clientX +
      (doc && doc.scrollLeft || body && body.scrollLeft || 0) -
      (doc && doc.clientLeft || body && body.clientLeft || 0);
    event.pageY = event.clientY +
      (doc && doc.scrollTop  || body && body.scrollTop  || 0) -
      (doc && doc.clientTop  || body && body.clientTop  || 0 );
  }
  return {x: event.pageX, y: event.pageY}
}


function registerTimelineMouseEvent(eventName){
  document.addEventListener(eventName, function(event){
    var element = event.target;
    // When ContentFlow is enabled, the event is caught by ChunkTrigger
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" ChunkTrigger ") > -1 ){
      var contentFlowBar = element.closest('.ContentFlowBar')
      reportTimelineMouseEvent(contentFlowBar, eventName, event);
      return;
    }
    // When ContentFlow is disabled, the event is caught by ContentFlowBar
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" ContentFlowBar ") > -1 ){
      reportTimelineMouseEvent(element, eventName, event);
      return;
    }
    console.log('mouse '+eventName)
    if(eventName=='mousemove' && (" " + element.getAttribute("class") + " ").replace(/[\n\t]/g, " ").indexOf(" StoryTag ") > -1 ){
      var rect = element.getBoundingClientRect();
      var posX = window.scrollX + rect.left;
      var positionInResource = (event.pageX - posX) / rect.width;
      app.ports.mouseMovedOnStoryTag.send(positionInResource);
      return;
    }
  });
}


function reportTimelineMouseEvent(element, eventName, event){
  if(eventName=='mousemove'){
    var now = new Date().getTime();
    // no need to report more than a handful mousemove events per second. be nice to the network.
    if(now-timeOfLastMouseMove < 250){
      return;
    }
    timeOfLastMouseMove = now;
  }
  var rect = element.getBoundingClientRect();
  var posX = window.scrollX + rect.left;
  var position = (event.pageX - posX) / rect.width;
  app.ports.timelineMouseEvent.send({eventName: eventName, position: position});
}


function playWhenPossible(vid, position){
  vid.currentTime = position;
  tryPlaying(vid, position, 50);
}


function tryPlaying(vid, position, attempts){
  if(vid.readyState>=2){//HAVE_CURRENT_DATA
    vid.play();
  }else if(attempts>0){
    setTimeout(function(){
      tryPlaying(vid, position, attempts-1);
    }, 500);
  }
}
