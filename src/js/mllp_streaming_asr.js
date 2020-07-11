// IE polyfill
(function () {

  if ( typeof window.CustomEvent === "function" ) return false;

  function CustomEvent ( event, params ) {
    params = params || { bubbles: false, cancelable: false, detail: null };
    var evt = document.createEvent( 'CustomEvent' );
    evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
    return evt;
   }

  window.CustomEvent = CustomEvent;
})();

(function(window) {
  // You can enable the strict mode commenting the following line  
  // 'use strict';

  String.prototype.capitalize = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
  }

  function MLLPStreamingASR() {
    var _MLLPStreamingASR = {};

    /* Web Audio API variables */
    var bufferLengthInSeconds = 0.1250;
    var ws_url = 'wss://fuster.dsic.upv.es:8000';
    var rtsocket = null;
    var rtsocket_connected = false;
    var protocolStatus = 0; // 0 = CLOSED, 1 = READY
    var audioContext = null;
    var scriptProcessorNode = null;
    var microphoneNode = null;
    var gainNode = null;
    var analyserNode = null;
    
    _MLLPStreamingASR.setMicVolume = function(volume) {
      gainNode.gain.value = volume;
    };

    // Private event sending
    function _sendEvent(name, dataObject) {
      var event = new CustomEvent('mllp:' + name, {detail: dataObject});
      window.dispatchEvent(event);
    }

    /*** 
     * 
     * Private Web Audio API functions 
     * 
     * ***/
    function _initPipeline() {
      gainNode = audioContext.createGain();
      analyserNode = audioContext.createAnalyser();
      gainNode.gain.value = 1.0;
      gainNode.connect(analyserNode);
    }

    function _gotStream(stream) {
      microphoneNode = audioContext.createMediaStreamSource(stream);
      microphoneNode.connect(gainNode);

      // Start Web Socket connection...
      _socket_connect();
    }

    function _runPipelineMic() {
      if (scriptProcessorNode == null) {
        scriptProcessorNode = (audioContext.createScriptProcessor || audioContext.createJavaScriptNode).call(audioContext, 4096, 1, 1);
        gainNode.connect(scriptProcessorNode);
        scriptProcessorNode.connect(audioContext.destination);
      }
      scriptProcessorNode.onaudioprocess = _sendMicrophoneData;
      send_buffer_FACTOR= audioContext.sampleRate/16000.0
      send_buffer_iter= send_buffer_FACTOR/2.0
      send_buffer_pos= 0;
      send_buffer_begin= Math.round(send_buffer_iter)
      send_buffer_end= Math.round(send_buffer_iter+send_buffer_FACTOR)
      send_buffer_i= send_buffer_begin
      send_buffer_val= 0.0
      audioContext.resume();
    }

    var send_buffer= new Int16Array(16000*bufferLengthInSeconds)
    var send_buffer_pos= 0 // Must be initialized
    var send_buffer_FACTOR= 0 // Must be initialized
    var send_buffer_iter= 0 // Must be initialized
    var send_buffer_begin= 0 // Must be initialized
    var send_buffer_end= 0 // Must be initialized
    var send_buffer_i= 0 // Must be initialized
    var send_buffer_val= 0.0 // Must be initialized
    function _sendMicrophoneData(e) {
      if (rtsocket_connected && protocolStatus == 1)
      {
          data= e.inputBuffer.getChannelData(0);
          while ( send_buffer_i < e.inputBuffer.length )
          {
              send_buffer_val+= data[send_buffer_i++];
              if ( send_buffer_i == send_buffer_end )
              {
                  send_buffer_val/= (send_buffer_end-send_buffer_begin);
                  send_buffer[send_buffer_pos++]= Math.round((send_buffer_val*32767.5)-0.5);
                  if ( send_buffer_pos == send_buffer.length )
                  {
                      rtsocket.send ( send_buffer );
                      send_buffer_pos= 0;
                  }
                  send_buffer_iter+= send_buffer_FACTOR;
                  send_buffer_begin= Math.round(send_buffer_iter);
                  send_buffer_end= Math.round(send_buffer_iter+send_buffer_FACTOR);
                  send_buffer_i= send_buffer_begin;
                  send_buffer_val= 0.0;
              }
          }
          send_buffer_i-= e.inputBuffer.length;
          send_buffer_iter-= e.inputBuffer.length;
          send_buffer_begin-= e.inputBuffer.length;
          send_buffer_end-= e.inputBuffer.length;
      }
      else {
        _sendEvent('error', {'details': 'Unable to send microphone input: the connection with the transcription service is not ready'});
      }
    }

    // Public initialization function (should be called first)
    _MLLPStreamingASR.init = function() {

      window.AudioContext = window.AudioContext || window.webkitAudioContext;
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;

      if (window.AudioContext) {
        audioContext = new AudioContext();
        audioContext.suspend().then(_initPipeline);
        
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          try {
            navigator.mediaDevices.getUserMedia({audio: true}).then(_gotStream).catch(function(err) {
              _sendEvent('error', {'details': 'Unable to access microphone input: ' + err});
              console.log("[MLLP] Unable to access microphone input: " + err);
            });
          } catch (e) {
            _sendEvent('error', {'details': 'Unable to access microphone input: ' + e});
            console.log("[MLLP] Unable to access microphone input: " + e);
          }
        }
        else if (navigator.getUserMedia) {
          // Legacy (deprecated)
          try {
            navigator.getUserMedia({audio: true}, _gotStream, function(err) {
              _sendEvent('error', {'details': 'Unable to access microphone input: ' + err});
              console.log("[MLLP] Unable to access microphone input: " + err);
            });
          } catch (e) {
            _sendEvent('error', {'details': 'Unable to access microphone input: ' + e});
            console.log("[MLLP] Unable to access microphone input: " + e);
          }
        }
        else {
          // Unsupported browser
          _sendEvent('error', {'details': 'Sorry, your browser does not support HTML5 Web Audio API (getUserMedia)'});
          console.log("[MLLP] getUserMedia is not supported");
        }
      }
      else {
        // Unsupported browser
        _sendEvent('error', {'details': 'Sorry, your browser does not support HTML5 Web Audio API'});
        console.log("[MLLP] Web Audio API is not supported");
      }
    };

    _MLLPStreamingASR.startRecognition = function(system_id) {
      micBuffer = null;
      _protocol_open(system_id);
    };

    _MLLPStreamingASR.stopRecognition = function() {
      scriptProcessorNode.onaudioprocess = null;
      micBuffer = null;
      if (protocolStatus == 1) {
        _protocol_close();
      }
    }

    /*** 
     * 
     * Private Web Socket functions 
     * 
     * ***/
    function _socket_connect() {
      try {
        rtsocket = new WebSocket(ws_url);
        rtsocket.onopen = function () {
          rtsocket_connected = true;
          _sendEvent('connected');
        };
        rtsocket.onerror = function (error) {
          protocolStatus = 0;
          rtsocket_connected = false;
          console.log('[MLLP] Web Socket connection error: ', error);
          // Probably the Web Socket server is unavailable
          _sendEvent('error', {'details': 'Sorry, the transcription service seems not available at the moment (unable to establish connection).'});
        };
        rtsocket.onclose = function () {
          protocolStatus = 0;
          rtsocket_connected = false;
          _sendEvent('disconnected');
        };
        rtsocket.onmessage = function (e) {
          var msg = JSON.parse(e.data);
          if ("code" in msg) {
            switch(msg["code"]) {
              case "SYSTEMS":
                if ("content" in msg) {
                  var content = msg["content"];
                  if (typeof content === 'string') content = JSON.parse(msg["content"]);
                  _sendEvent('systems', content);
                }
                break;

              case "READY":
                protocolStatus = 1;
                _runPipelineMic();
                _sendEvent('ready');
                break;

              case "ERR":
                protocolStatus = 0;
                if (scriptProcessorNode != null) scriptProcessorNode.onaudioprocess = null;
                micBuffer = null;
                bootbox.alert("[MLLP] Connection with the transcription server was closed: "+msg["text"]);
                callbackOnOpen = null;
                rtsocket_connected = false;
                _sendEvent('error', {'details': msg["text"]});
                break;

              case "HYP":
                _sendEvent('partial', {
                  'fixed': _filterSpecialTokens(msg["text-novar"]).trim(), 
                  'var': _filterSpecialTokens(msg["text-var"]).trim()
                });
                break;

              case "RES":
                _sendEvent('result', {
                  'fixed': _filterSpecialTokens(msg["text-novar"]).trim().capitalize()
                });
                break;

              case "RESET":
                _sendEvent('reset');
                break;

              case "END":
                protocolStatus = 0;
                if (scriptProcessorNode != null) scriptProcessorNode.onaudioprocess = null;
                micBuffer = null;
                _sendEvent('end');
                break;
              
              default:
                break;
            }
          }
          else {
            console.log("[MLLP] Unexpected message");
          }
        };
      } catch(e) {
        _sendEvent('error', {'details': 'Connection with transcription server could not be established: ' + e});
        console.log('[MLLP] Connection with transcription server could not be established: ' + e);
      }
    }

    /*** 
     * 
     * Custom protocol functions 
     * 
     * ***/
    function _protocol_open(system_id) {
      if (rtsocket_connected) {
        var dataJson = {
          "code": "OPEN",
          "sampleRate": 16000,
          "bitDepth": 16,
          "system_id": system_id
        };
        rtsocket.send(JSON.stringify(dataJson));
      }
      else {
        _sendEvent('error', {'details': 'Connection with transcription server is not ready'});
      }
    }

    function _protocol_close() {
      if (rtsocket_connected) {
        rtsocket.send(JSON.stringify({"code": "CLOSE"}));
      }
    }

    function _protocol_pause() {
      if (rtsocket_connected) {
        rtsocket.send(JSON.stringify({"code": "PAUSE"}));
      }
    }

    /***
     * Aux functions
     */

    function _filterSpecialTokens(text) {
      return text.replace(new RegExp(" <s> ", 'g'), ", ").replace(new RegExp("<s>", 'g'), '').replace(new RegExp(" <unk> ", 'g'), " ").replace(new RegExp("<unk>", 'g'), '');
    }
  
    return _MLLPStreamingASR;
  }

  // We need that our library is globally accesible, then we save in the window
  if(typeof(window.MLLPStreamingASR) === 'undefined') {
    window.MLLPStreamingASR = MLLPStreamingASR();
  }
})(window);