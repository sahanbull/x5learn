loadYoutubeApiAsynchronously();


var player;
var playerStartSeconds;


function loadYoutubeApiAsynchronously(){
  var tag = document.createElement('script');

  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
}


function onYouTubeIframeAPIReady() {
  // console.log('onYouTubeIframeAPIReady');
}


// The API will call this function when the video player is ready.
function onPlayerReady(event) {
  event.target.seekTo(playerStartSeconds);
  event.target.playVideo();
}

// The API calls this function when the player's state changes.
function onPlayerStateChange(event) {
  // console.log('player state change');
  if (event.data == YT.PlayerState.PLAYING) {
  }
}


function embedVideo(inspectorParams){
  playerStartSeconds = inspectorParams.startSeconds;
  player = new YT.Player('player', {
    height: '390',
    width: '720',
    videoId: inspectorParams.videoId,
    startSeconds: playerStartSeconds,
    events: {
      'onReady': onPlayerReady,
      'onStateChange': onPlayerStateChange
    }
  });
}
