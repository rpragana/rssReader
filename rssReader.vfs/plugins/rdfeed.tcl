############ feed reader
package require http
package require json
package require json::write

namespace eval ::rdfeed { 
	variable rsslist {}
	variable cacheDir [file join [file dirname $::starkit::topdir] \
		rssReader-cache]
	variable feeds

	file mkdir $cacheDir
	set dfn [file join $cacheDir FEEDS]
	if {[file exists $dfn]} {
		set f1 [open $dfn r]
		set feeds [read $f1]
		close $f1
	}
}

proc ::rdfeed::conv {url} {
	### trim first http(s):
	set ix [string first : $url]
	incr ix 
	set s [string range $url $ix end]
	set s [string trimleft $s /]
	set s [string map {/ _} $s]
	return $s
}

proc ::rdfeed::refreshCB {url {origUrl ""} tok} {
	variable cacheDir
	variable feeds
	puts "refreshCB: $url -- $origUrl --> [::http::status $tok]"
	upvar #0 $tok state
	set stHttp [::http::ncode $tok]
	if {[string index $stHttp 0] eq "3"} {
		set url1 [dict get $state(meta) Location]
		if {$origUrl ne ""} {
			set url $origUrl
		}
		::http::cleanup $tok
		tatu::log "Refresh URL REDIRECTION: url=$url1"
		if {[catch {::http::geturl $url1 -command \
					[list ::rdfeed::refreshCB $url1 $url]} err]} {
			tatu::log "Refresh URL ERROR: url=$url1 err=$err"
		}
		return
	}
	if {$origUrl ne ""} {
		set url $origUrl
	}
	if {[::http::status $tok] eq "ok"} {
		set d [::http::data $tok]
		set cfn [file join $cacheDir [conv $url]] 
		set f [open $cfn w]
		puts $f $d
		close $f
	} else {
		set feeds [dict remove $feeds [conv $url]]
		set dfn [file join $cacheDir FEEDS]
		set f1 [open $dfn w]
		puts -nonewline $f1 $feeds
		close $f1
	}
	::http::cleanup $tok
}

proc ::rdfeed::refresh {} {
	variable cacheDir
	variable feeds
	set n 0
	foreach {key url} $feeds {
		incr n
		set cfn [file join $cacheDir $key]
		if {![file exists $cfn] ||
				([clock seconds] - [file mtime $cfn]) > (120 * 60)} {
			### refresh files older than 120 minutes ^^^
			if {![file exists $cfn]} {
			  close [open $cfn w]
			}	  
			file mtime $cfn [clock seconds]
			puts "REFSH: $n $key"
			catch {::http::geturl $url \
				-command [list ::rdfeed::refreshCB $url ""]} err
			break
		}
	}
	puts "REFRESH: $n"	
	after [expr 2 * 1000] ::rdfeed::refresh
	### refresh ^ another in 2 seconds
}

proc ::rdfeed::cback {conn url tok} {
	variable cacheDir
	variable feeds
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
	set d [::http::data $tok]
	set cfn [file join $cacheDir [conv $url]] 
	set f [open $cfn w]
	puts $f $d
	close $f
	### save dict with feeds
	dict set feeds [conv $url] $url
	set dfn [file join $cacheDir FEEDS]
	set f1 [open $dfn w]
	puts $f1 $feeds
	close $f1

	$conn out $d
	$conn respond
	#puts "*** size=$state(currentsize) http_status=$stHttp url=$state(url)"
	::http::cleanup $tok
}

proc ::rdfeed::rdfeed {conn params} {
	variable cacheDir
	variable rsslist
	variable feeds
	set url [$conn queryData url]
	set cmd [$conn queryData cmd]
	if {"$cmd" eq "rawfeeds"} {
		set dir [file dirname $::starkit::topdir]
		set bmarks [file join $dir [$conn queryData bmarks]]
		#$conn outHeader 200 {Content-Type text/html}
		$conn outHeader 200 {Content-Type application/xml; charset:UTF-8}
		set f [open $bmarks r]
		set dt [read $f]
		close $f
		$conn out $dt
		return
	}
	### see if already cached
	set cfn [file join $cacheDir [conv $url]]
	if {[file exists $cfn]} {
		puts "GET CACHED $url"
		set f [open $cfn r]
		set d [read $f]
		close $f
		$conn outHeader 200 {Content-Type application/xml; charset:UTF-8} 0
		$conn out $d
		return	
	}
	puts "READ FEED $url"
	#$conn outHeader 200 {Content-Type text/xml} 1
	$conn outHeader 200 {Content-Type application/xml; charset:UTF-8} 1
	if {[catch {::http::geturl $url \
				-command [list ::rdfeed::cback $conn $url]} err]} {
		tatu::log "URL ERROR: url=$url err=$err"
	}
}

after 10000 ::rdfeed::refresh

tatu::addRoute "/rdfeed" ::rdfeed::rdfeed 

puts "RSS Feed Reader started - server at http://localhost:$tatu::server(port)"

