// Helpers and interop between Elm and JavaScript

var timeOfLastMouseMove = new Date().getTime();

var lastPageScrollOffset = 0;

var videoEventThrottlePosition = 0; // Limit the frequency of events sent to Elm
var isVideoPlaying = false;
var videoPlayPosition = 0;


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
      vid.currentTime = position;
      vid.play();
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


function startAnimationWhenModalIsReady(youtubeEmbedParams) {
  var modalId = youtubeEmbedParams.modalId;
  if(window.document.getElementById(modalId)==null) {
    setTimeout(function() {
      startAnimationWhenModalIsReady(youtubeEmbedParams);
    }, 15);
  }
  else{
    var card = document.activeElement;
    var modal = document.getElementById(modalId);
    card.blur(); // remove the blue outline
    app.ports.modalAnimationStart.send({frameCount: 0, start: positionAndSize(card), end: positionAndSize(modal)});
    setTimeout(function(){
      app.ports.modalAnimationStop.send(12345);
      if(youtubeEmbedParams.videoId.length>0){
        embedYoutubeVideo(youtubeEmbedParams);
      }else{
        var vid = getHtml5VideoPlayer();
        if(vid){
          vid.onloadedmetadata = function() {
            app.ports.html5VideoDuration.send(vid.duration);
            if(youtubeEmbedParams.playWhenReady){
              vid.currentTime = youtubeEmbedParams.fragmentStart * vid.duration;
              vid.play();
            }
          };
          vid.onplay = function() {
            isVideoPlaying = true;
            videoPlayPosition = vid.currentTime;
            app.ports.html5VideoStarted.send(videoPlayPosition);
            videoEventThrottlePosition = videoPlayPosition;
            // console.log('started!');
          };
          vid.onpause = function() {
            isVideoPlaying = false;
            videoPlayPosition = vid.currentTime;
            app.ports.html5VideoPaused.send(videoPlayPosition);
            // console.log('paused!');
          };
          vid.ontimeupdate = function() {
            videoPlayPosition = vid.currentTime;
            if(isVideoPlaying){
              if(videoPlayPosition > videoEventThrottlePosition + 10){
                // console.log("SENT");
                app.ports.html5VideoStillPlaying.send(videoPlayPosition);
                videoEventThrottlePosition = videoPlayPosition;
              }
              // console.log('still playing: '+videoPlayPosition);
            }else{
              app.ports.html5VideoSeeked.send(videoPlayPosition);
              videoEventThrottlePosition = 0;
              // console.log('seek: '+videoPlayPosition);
            }
          };
        }else{
          // console.log('video not found');
        }
      }
    }, 110);
    return;
  }
}


function getHtml5VideoPlayer(){
  return document.getElementById("Html5VideoPlayer");
}

// function embedYoutubePlayerOnResourcePage(youtubeEmbedParams) {
//     setTimeout(function(){
//       if(youtubeEmbedParams.videoId.length>0){
//         embedYoutubeVideo(youtubeEmbedParams);
//       }
//     }, 200);
// }


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

  document.addEventListener("mousemove", function(event){
    var element = event.target;
    // if((" " + element.getAttribute("class") + " ").replace(/[\n\t]/g, " ").indexOf(" StoryTag ") > -1 ){
    //   var rect = element.getBoundingClientRect();
    //   var posX = window.scrollX + rect.left;
    //   var positionInResource = (event.pageX - posX) / rect.width;
    //   app.ports.mouseMovedOnStoryTag.send(positionInResource);
    // }

    // When ContentFlow is enabled, the mousemove event is caught by ChunkTrigger
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" ChunkTrigger ") > -1 ){
      var fragmentsBar = element.closest('.FragmentsBar')
      if(fragmentsBar){
        reportScrubbing(fragmentsBar, event);
      }
    }

    // When ContentFlow is disabled, the mousemove event is caught by FragmentsBar
    if((" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(" FragmentsBar ") > -1 ){
      reportScrubbing(element, event);
    }
  });

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


function reportScrubbing(fragmentsBar, event){
  var rect = fragmentsBar.getBoundingClientRect();
  var posX = window.scrollX + rect.left;
  var positionInResource = (event.pageX - posX) / rect.width;
  app.ports.scrubbed.send(positionInResource);
}
