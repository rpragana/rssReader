/*
 * Main javascript functions
 *
 */

/*
require( ["jquery","jquery-migrate-1.1.1","bootstrap-transition",
    "bootstrap-alert", "bootstrap-modal", "bootstrap-dropdown",
    "bootstrap-scrollspy", "bootstrap-tab", "bootstrap-tooltip",
    "bootstrap-popover", "bootstrap-button", "bootstrap-collapse",
    "bootstrap-carousel", "bootstrap-typeahead", "jquery.ui.position",
	"jquery.contextMenu", "jqueryFileTree", "edit_area_full",
	"jquery.jfeed", "jquery.dateFormat-1.0", "jquery.ajax-retry"
	],function(){
*/

var isValidDate = function (d) {
  if ( Object.prototype.toString.call(d) !== "[object Date]" )
    return false;
  return !isNaN(d.getTime());
}

/**
 * jQuery.fn.sortElements
 * --------------
 * @param Function comparator:
 *   Exactly the same behaviour as [1,2,3].sort(comparator)
 *   
 * @param Function getSortable
 *   A function that should return the element that is
 *   to be sorted. The comparator will run on the
 *   current collection, but you may want the actual
 *   resulting sort to occur on a parent or another
 *   associated element.
 *   
 *   E.g. $('td').sortElements(comparator, function(){
 *      return this.parentNode; 
 *   })
 *   
 *   The <td>'s parent (<tr>) will be sorted instead
 *   of the <td> itself.
 */
jQuery.fn.sortElements = (function(){
    var sort = [].sort;
    return function(comparator, getSortable) {
        getSortable = getSortable || function(){return this;};
        var placements = this.map(function(){
            var sortElement = getSortable.call(this),
                parentNode = sortElement.parentNode,
                // Since the element itself will change position, we have
                // to have some way of storing its original position in
                // the DOM. The easiest way is to have a 'flag' node:
                nextSibling = parentNode.insertBefore(
                    document.createTextNode(''),
                    sortElement.nextSibling
                );
            return function() {
                if (parentNode === this) {
                    throw new Error(
                        "You can't sort elements if any one is a descendant of another."
                    );
                }
                // Insert before flag:
                parentNode.insertBefore(this, nextSibling);
                // Remove flag:
                parentNode.removeChild(nextSibling);
            };
        });
        return sort.call(this, comparator).each(function(i){
            placements[i].call(getSortable.call(this));
        });
    };
})();

function processFeed(feedurl,siteurl,subject) {
	return function(feed) {
		//console.log('******* PROCESS '+feedurl+'\nFEED------------\n'+
		//		JSON.stringify(feed)+'\n\n\n\n');
		var markup = '';
		var rendered;
		var chkdt;
		var chkdt1;
		var newsclass;
		var n;
		if (!feed.items) { 
			$(document).trigger('countersUpdate',[0]);
			return; 
		}	
		n = feed.items.length;
		n = n<15 ? n : 15;	
		$(document).trigger('countersUpdate',[n]);
		
		rendered=0;
		chkdt = chkdt1 = new Date().getTime(); 
		chkdt -= 60*60*24*1000; // 24 hours ago
		chkdt1 -= 60*60*48*1000; // 48 hours ago
		//chkdt -= 60*60*24*1000*5; // 5 days ago
		for(var i = 0; i < feed.items.length && i < 20; i++) {
			var item = feed.items[i];
			var itemDt = new Date(item.updated);
			var tstamp;
			var dt;
			if (isValidDate(itemDt)) {
				dt = $.format.date(itemDt, 'dd/M/yyyy');
				tstamp = itemDt.getTime();
			} else {
				//break;
				dt = "--/--/----";
				itemDt = 0;
				tstamp = 0;
			}
			//if (itemDt.getTime() < chkdt) { break; }
			if (rendered === 0) {
				rendered=1;
		//		markup += '<div class="feedSrc" timestamp="'
		//				+itemDt.getTime()+'" subject="'
		//				+subject.attr('title')+'"><h5>'
		//				+subject.attr('title')
		//				+' - <a href="'+siteurl+
		//			'" target="_blank">'+feed.title+'</a></h5>';
				//console.log('ADDED '+feed.link+' *** DATE='+dt);
			}
			newsclass = "";
			if (itemDt.getTime() > chkdt) {
				newsclass = "news";
			} else if (itemDt.getTime() > chkdt1 ) {
				newsclass = "news1";
			}
//<i class="icon-external-link"></i>
			markup += '<li timestamp="'+tstamp+'" class="'+newsclass+'">'
				+'<div class="feedprov">'+feed.title+'</div>'
				+'<div class="itemdt">'+' '+/*i+' * '+*/dt+'</div> '
				+ '<a class="itemtit" href="'  
					+ item.link + '" target="_blank">'
				+ '<i class="icon-external-link"></i></a>'
				+ '<a class="itemtitle" tabindex="-1" href="#">'
				+ item.title + '</a>'
				+ '<div class="itemdesc">'+item.description+'</div>'
				+ '</li>'
		} 
		if (rendered) {
			//markup += '</div>';
	
			jQuery('#feedContents').append(markup);
			// --- sort .feedSrc elements ---
			//$('#feedContents .feedSrc').sortElements(function(a, b){
			//	return $(b).attr('timestamp') > 
			//		$(a).attr('timestamp') ? 1 : -1;
			//});
			$('#feedContents li[timestamp]')
				.sortElements(function(a, b){
					return $(b).attr('timestamp') > 
						$(a).attr('timestamp') ? 1 : -1;
			});
			/*$('#feedContents .feedSrc').sortElements(function(a, b){
				return $(a).attr('subject') > 
					$(b).attr('subject') ? 1 : -1;
			});*/

		}
	}    
}

$(window).load(function(){
	var n=0;
	var lkcnt = 0;
	var feedcnt = 0;
	var selFeedsCnt=0;
	var xmldef;



	$(document).on('countersUpdate',function(event,links){
		lkcnt += links; 
		$('#lkcnt').text(lkcnt);
		feedcnt++; 
		$('#feedcnt').text(feedcnt);
		$('#selFeedsCnt').text(selFeedsCnt);
	});
	$('#subjects').on('click','li',function(ev){
		var seltxt = $(this).text();
		//alert(seltxt);
		$('#refresh').text(seltxt);
		$(document).trigger('refresh',seltxt);
	});	
	$(document).on('refresh',function(event,subj){
		console.log("WILL FETCH SUBJECT "+subj);
		xmldef.done(function(xml){
			var feedsList;	
			lkcnt = 0;
			feedcnt = 0;
			selFeedsCnt=0;
			console.log("FETCHING FEEDS OF SUBJECT "+subj);
			jQuery('#feedContents').html("");
			$(xml).find('outline').not('[xmlUrl]').each(function(){
				var subject=$(this);
				if (subject.attr('title') === subj) {
					var selFeeds =	subject.find('outline[xmlUrl]');
					selFeedsCnt = selFeeds.length;
					selFeeds.each(function(ix) {
						 feedurl = $(this).attr('xmlUrl');	
						var siteurl = $(this).attr('htmlUrl');	
						//var proxyurl = "/rdfeed?url="+feedurl;
						var proxyurl = "/rdfeed?url="+encodeURIComponent(feedurl);

						//----- get each individual rss feed
						//console.log('START GET FEEDURL '+feedurl);
						jQuery.getFeed({
							url: proxyurl,
							success: processFeed(feedurl,siteurl,subject)
						});
					});
				}
			});
		});
	});

	var reload = function() {
		var feedListurl="/rdfeed?cmd=rawfeeds&bmarks=subscriptions.xml"
		console.log("WILL GET "+feedListurl);
		xmldef = $.ajax({
			type: "GET",
			url: feedListurl,
			dataType: "xml"
		}).retry({times: 3, timeout: 10000});

		xmldef.done(function(xmldata){
			//var items=0;
			$('#subjects li').remove();
			$(xmldata).find('outline').not('[xmlUrl]').each(function(){
				var subject=$(this);
				var subjtit = subject.attr('title');
				console.log("SUBJECT "+subjtit);
				var h = '<li><a class="subj" tabindex="-1">'
					+subjtit+'</a></li>';
				$('#subjects').append(h);
			});
		});
	};

	$(document).on('click','#reload',function(ev){
		reload();
	});

});

$(window).on('load',function(){
	console.log('STARTING RELOAD FUNCTION BY TRIGGER');
	$('#reload').trigger('click');
});
	

key('n',function(){ /* focus next li */
	if ($(':focus').prev('.itemdt').length == 0) {
		$('.itemtit:first').focus(); 
	} else {
		$(':focus').parent().next().children('a.itemtit').focus(); 
	}
});

key('p',function(){ /* focus prev li */
	if ($(':focus').prev('.itemdt').length == 0) {
		$('.itemtit:last').focus(); 
	} else {
		$(':focus').parent().prev().children('a.itemtit').focus(); 
	}
});

var open_in_new_tab = function(url ) {
  var win=window.open(url, '_blank');
  window.focus();
}

key('v',function(){ /* open link */
	if ($(':focus').prev('.itemdt').length) {
		open_in_new_tab($(':focus').attr('href'));
	}
});

$(document).on('click','.itemtitle',function(ev){
	var p = $(ev.target).parent();	
	var show=1;
	var dsc;
	//console.log('target:'+ev.target);
	p.children('a.itemtit').focus();	
	dsc = p.children('.itemdesc');

	if (dsc.filter(':visible').length) {
		show=0;
	} 
	//$('.itemdesc').css({display: 'none'});
	$('.itemdesc').removeClass('selected');
	if (show) {
		//dsc.show();
		dsc.addClass('selected');
	}
	//$.scrollTo(p.children('a.itemtit'),1000, {offset: {top: -120, left: 0} });
	return false;
});


//});


