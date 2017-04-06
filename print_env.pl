#!/usr/bin/perl

use warnings;
use strict;

print("Content-Type: text/html\n\n");

print("<html><head><title>hi</title></head><body><table>");
foreach my $sKey (keys %ENV){
	print("<tr><td>" . $sKey . "</td><td>" . $ENV{$sKey} . "</td></tr>");
}


print("</table></body></html>");

