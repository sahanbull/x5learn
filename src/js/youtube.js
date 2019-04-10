loadYoutubeApiAsynchronously();


var player;
var playerFragmentStart;


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
  player = event.target;
  player.seekTo(playerFragmentStart * player.getDuration());
  player.playVideo();
}

// The API calls this function when the player's state changes.
function onPlayerStateChange(event) {
  // console.log('player state change');
  if (event.data == YT.PlayerState.PLAYING) {
  }
}


function embedVideo(inspectorParams){
  playerFragmentStart = inspectorParams.fragmentStart;
  player = new YT.Player('player', {
    height: '400',
    width: '720',
    videoId: inspectorParams.videoId,
    events: {
      'onReady': onPlayerReady,
      'onStateChange': onPlayerStateChange
    }
  });
}
