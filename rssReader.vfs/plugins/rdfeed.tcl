############ feed reader
package require http
package require json
package require json::write

namespace eval ::rdfeed { 
	variable rsslist {}
}

proc ::rdfeed::cback {conn url tok} {
	upvar #0 $tok state
	#set stHttp [lindex $state(http) end]
	set stHttp [::http::ncode $tok]
	if {[string index $stHttp 0] eq "3"} {
		set url [dict get $state(meta) Location]
		::http::cleanup $tok
		tatu::log "URL REDIRECTION: url=$url"
		if {[catch {::http::geturl $url -command \
					[list ::rdfeed::cback $conn $url]} err]} {
			tatu::log "URL ERROR: url=$url err=$err"
		}
	}
	$conn out "[::http::data $tok]"
	$conn respond
	#puts "*** size=$state(currentsize) http_status=$stHttp url=$state(url)"
	::http::cleanup $tok
}

proc ::rdfeed::rdfeed {conn params} {
	variable rsslist	
	set url [$conn queryData url]
	set cmd [$conn queryData cmd]
	if {"$cmd" eq "rawfeeds"} {
		set bmarks [$conn queryData bmarks]
		#$conn outHeader 200 {Content-Type text/html}
		$conn outHeader 200 {Content-Type application/xml; charset:UTF-8}
		set f [open $bmarks r]
		set dt [read $f]
		close $f
		$conn out $dt
		return
	}
	puts "READ FEED $url"
	#$conn outHeader 200 {Content-Type text/xml} 1
	$conn outHeader 200 {Content-Type application/xml; charset:UTF-8} 1
	if {[catch {::http::geturl $url -command [list ::rdfeed::cback $conn $url]} err]} {
		tatu::log "URL ERROR: url=$url err=$err"
	}
}

tatu::addRoute "/rdfeed" ::rdfeed::rdfeed 

puts "RSS Feed Reader started - server at http://localhost:$tatu::server(port)"

