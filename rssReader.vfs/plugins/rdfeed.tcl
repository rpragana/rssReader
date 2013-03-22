############ feed reader
package require http
package require json
package require json::write
package require tdom
package require dns

namespace eval ::rdfeed { 
	variable rsslist {}
}

proc ::rdfeed::readRssList {} {
	variable rsslist	
	# read list of rss servers to grab
	set f [open bmarks.html r]
	set dhtml [read $f]
	close $f
	dom parse -html $dhtml doc
	set alst [$doc getElementsByTagName a]
	set rsslist {}
	foreach a $alst {
		lappend rsslist [list [$a getAttribute FEEDURL] [$a getAttribute HREF]]
	}
}

proc ::rdfeed::cback {conn tok} {
	### appended a large string (of newlines) to avoid losing chars
	### don't know where this bug is...
	#set ap [string repeat "\n" 1000]
	#$conn out "[::http::data $tok]$ap"
	$conn out "[::http::data $tok]"
	$conn respond
	upvar #0 $tok state
	set stHttp [lindex $state(http) end]
	puts "*** size=$state(currentsize) http_status=$stHttp url=$state(url)"
	::http::cleanup $tok
}

proc ::rdfeed::rdfeed {conn params} {
	variable rsslist	
	set url [$conn queryData url]
	set cmd [$conn queryData cmd]
	if {"$cmd" eq "feeds"} {
		readRssList
		set r {}
		set n 0
		$conn outHeader 200 {Content-Type application/json}
		foreach a1 $rsslist {
			lassign $a1 a u
			set s {}
			#lappend s n [json::write string [incr n]]
			lappend s feed [json::write string $a]
			lappend s url [json::write string $u]
			lappend r "\n[eval json::write object $s]"
		}	
		$conn out [eval json::write array $r]
		return
	}
	puts "READ FEED $url"
	$conn outHeader 200 {Content-Type text/xml} 1
	::http::geturl $url -command [list ::rdfeed::cback $conn]
}

tatu::addRoute "/rdfeed" ::rdfeed::rdfeed 

puts "RSS Feed Reader started - server at http://localhost:$tatu::server(port)"


