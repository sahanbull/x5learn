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
  setupYouTubePlayPositionFollower();
}


function onReadySeekAndPlay(event) {
  player = event.target;
  player.seekTo(playerFragmentStart * player.getDuration());
  player.playVideo();
}

function onReadySeek(event) {
  player = event.target;
  player.pauseVideo();
  player.seekTo(playerFragmentStart * player.getDuration());
  setTimeout(function() {
    player.pauseVideo();
  }, 300);
}

// The API calls this function when the player's state changes.
function onPlayerStateChange(event) {
  // console.log('player state change');
  if (event.data == YT.PlayerState.PLAYING) {
  }
}

function embedYoutubeVideo(youtubeEmbedParams){
  if(typeof YT === 'undefined' || YT.loaded!=1){
    setTimeout(function() { // try again after a short delay
      embedYoutubeVideo(youtubeEmbedParams);
    }, 20);
    return;
  }
  playerFragmentStart = youtubeEmbedParams.fragmentStart;
  player = new YT.Player('playerElement', {
    height: '400',
    width: '720',
    videoId: youtubeEmbedParams.videoId,
    events: {
      'onReady': youtubeEmbedParams.playWhenReady ? onReadySeekAndPlay : onReadySeek,
      'onStateChange': onPlayerStateChange
    }
  });
}

function setupYouTubePlayPositionFollower(){
  setInterval(function(){
    // see YouTube API documentation https://developers.google.com/youtube/iframe_api_reference#Playback_status
    if(player && player.getPlayerState && player.getPlayerState()==1){
      var fraction = player.getCurrentTime() / player.getDuration();
      app.ports.videoIsPlayingAtPosition.send(fraction);
    }
  }, 1000);
}
