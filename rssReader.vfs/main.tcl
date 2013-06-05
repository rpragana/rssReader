  package require starkit
  starkit::startup

### avoid running twice
if {[info procs bgerror] ne ""} {
	rename bgerror trdBgerror	
}
set localcfgf [file join $starkit::topdir localhost.json]
if {[file exists $localcfgf]} {
	set f [open $localcfgf r]
	set json [read $f]
	close $f
}
set port [lindex [regexp -inline {\"port\":[\ \t]*(\d+)} $json] 1]
if {[catch {socket localhost $port} sk] == 0} {
	catch {
		package require Tk
		wm withdraw .
		tk_messageBox -title "rssReader msg" -message "Can't run twice"
	}
	#puts "Can't run twice!"
	exit 1
}
catch {close $sk}
if {[info procs trdBgerror] ne ""} {
	rename trdBgerror bgerror
}
#############################################
  #package require tatu-tests
  package require tatu-loader

#source [file join $::starkit::topdir app tatu-loader.tcl]

