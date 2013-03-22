//
// debug.js - tatu debugger/logger
//
$(function(){
	var srvflags = { sh: false, am: false };
	$('#btn_exit').click(function(){
		$('#log').prepend('<pre class="error">Server exited!</pre>');
		$.getJSON('/log?cmd=eval&input=exit');
	});
	
	$('#btn_reload').click(function(){
		$('#log').prepend('<pre class="error">Reloading plugins</pre>');
		$.getJSON('/log?cmd=eval&input=loadPlugins');
	});
	
	$('#btn_toggleHeaders').click(function(){
		srvflags.sh=!srvflags.sh;
		$(this).toggleClass('active');
		$.getJSON('/log?cmd=toggleHeaders');
	});
	
	$('#btn_toggleModified').click(function(){
		srvflags.am=!srvflags.am;
		$(this).toggleClass('active');
		$.getJSON('/log?cmd=toggleModified');
	});
	
	$('#btn_clear').click(function(){
		$('#logger').html('');
	});
	
	var start=0;
	window.setInterval(function() {
		$.getJSON('/log?cmd=readlog&start='+start,"",
			function(data,textStatus,xhr) {
				var log=$('#logger');
				$.each(data, function(index,v){
					log.prepend('<pre class="logger">'+
						v.line+": "+v.msg+'</pre>');
				});
				if (data.length > 0) {
					start=data.pop().line;
				}});
	},2000);
	
	// keep flags on the server the same as local settings
	window.setInterval(function(){
		$.getJSON('/log?cmd=flags',"",
			function(data,textStatus,xhr) {
				if (data.allwaysModified != srvflags.am) {
					$.getJSON('/log?cmd=toggleModified');
				}	
				if (data.showHeaders != srvflags.sh) {
					$.getJSON('/log?cmd=toggleHeaders');
				}	
			});
	},5000);

	var wd = $('body').width();
	var history=[null];
	$('#log pre').css('width',wd);	
	$('#cmd').keydown(function(ev){
		//console.log("shift:"+ev.shiftKey+" which:"+ev.which);
		if (!ev.shiftKey && ev.which == 13) {
			var log=$('#log');
			var cmd=$('#cmd textarea').val();
			if (cmd.length > 0) {
				$.getJSON('/log?cmd=eval&input='+
						encodeURIComponent(cmd),
						"",function(data,textStatus,xhr){
					if (!data.error) {
						history.unshift(cmd);
						log.prepend('<pre class="answer">'+
							data.answer+'</pre>');
						$('#cmd textarea').val("");
					} else {
						log.prepend('<pre class="error">'+
							data.error+'</pre>');
					}
					log.prepend('<pre class="input">'+
						cmd+'</pre>');	
				});
			}
			return false;
		} else if (ev.which == 38) {
			//if (history[0] != null) {
				$('#cmd textarea').val(history[0]);
				history.push(history.shift());
			//}
			return false;
		} else if (ev.which == 40) {
			//if (history[0] != null) {
				$('#cmd textarea').val(history[0]);
				history.unshift(history.pop());
			//}
			return false;
		}
		return true;
	});
}); 



