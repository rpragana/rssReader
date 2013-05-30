package require json
package require json::write

namespace eval ::echo {
};

proc echo::echo {conn parms} {
	#$conn outHeader 200 {Content-Type text/plain}
	#set vars [$conn info vars]
	#foreach v $vars {
	#	catch {$conn out "$v = [array get $v]\n\n"}
	#}
	#$conn out	"conn vars = [$conn info vars]"
	#$conn out  "\n\nconn = $conn"

	$conn outHeader 200 {Content-Type application/json; charset=utf-8}
	set s {}
	foreach v [$conn queryNames] {
		lappend s $v [json::write string [$conn queryData $v]]
	}
	$conn out [eval json::write object $s]
}

tatu::addRoute "/echo" ::echo::echo 

