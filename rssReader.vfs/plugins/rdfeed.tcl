############ feed reader
package require http
package require json
package require json::write

namespace eval ::rdfeed { 
	variable rsslist {}
}

proc ::rdfeed::cback {conn tok} {
	$conn out "[::http::data $tok]"
	$conn respond
	upvar #0 $tok state
	set stHttp [lindex $state(http) end]
	#puts "*** size=$state(currentsize) http_status=$stHttp url=$state(url)"
	::http::cleanup $tok
}

proc ::rdfeed::rdfeed {conn params} {
	variable rsslist	
	set url [$conn queryData url]
	set cmd [$conn queryData cmd]
	if {"$cmd" eq "rawfeeds"} {
		set bmarks [$conn queryData bmarks]
		$conn outHeader 200 {Content-Type text/html}
		set f [open $bmarks r]
		set dt [read $f]
		close $f
		$conn out $dt
		return
	}
	puts "READ FEED $url"
	$conn outHeader 200 {Content-Type text/xml} 1
	if {[catch {::http::geturl $url -command [list ::rdfeed::cback $conn]} err]} {
		tatu::log "URL ERROR: url=$url err=$err"
	}
}

tatu::addRoute "/rdfeed" ::rdfeed::rdfeed 

puts "RSS Feed Reader started - server at http://localhost:$tatu::server(port)"

