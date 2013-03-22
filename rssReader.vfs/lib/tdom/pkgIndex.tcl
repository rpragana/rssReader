# return a platform designator, including both OS and machine
proc platform {} {
    global tcl_platform
    set plat [lindex $tcl_platform(os) 0]
    set mach $tcl_platform(machine)
    switch -glob -- $mach {
        sun4* { set mach sparc }
        intel -
        i*86* { set mach x86 }
        "Power Macintosh" { set mach ppc }
    }
    return "$plat-$mach"
}

proc loadlib {dir package version} {
    global tcl_platform
    set lib $package[info sharedlibextension]
	set name [file join $dir .. .. .. library [platform] $lib]
	if { [file exists $name] } { return $name }
    load "[file join $dir [platform] $lib]"
}

package ifneeded tdom 0.7.8 [list loadlib $dir tdom 0.7.8]\n[list source "[file join $dir tdom.tcl]"]
package ifneeded tdomhtml 0.1.0.1 [list package provide tdomhtml 0.1.0.1; set _V_ 0.1.0.1; source "[file join $dir tdomhtml.tcl]"]
package ifneeded tnc 0.3.0  [list loadlib $dir tnc 0.3.0]
