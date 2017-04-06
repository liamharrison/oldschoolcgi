#!/usr/bin/perl

use warnings;
use strict;

use DBI;

our $sLogsPath = "/var/www/files_lighttpd/findme/logs";
our $sDBFilePath = "/var/www/files_lighttpd/findme/findme.db";

sub respondQuit(;$){

	my $sMessage = shift();

	print("Status: 404 Not Found\r\n");
	print("Content-Type: text/html\r\n\r\n");

	if(defined($sMessage)){

		open(my $fhOutput, ">>$sLogsPath/$$.list.out");
		print($fhOutput time() . " " . $sMessage . "\n");
		close($fhOutput);
	}

	print("<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1></body></html>");
	exit(0);
}

my $sQueryText = "SELECT e.name AS name, d.value AS value, e.checkin AS checkin, d.dt AS dt ";
$sQueryText .= "FROM data d ";
$sQueryText .= "INNER JOIN (SELECT entity, max(dt) AS maxdt FROM data GROUP BY entity) AS maxentity ON maxentity.entity = d.entity ";
$sQueryText .= "INNER JOIN entity AS e ON e.id = d.entity ";
$sQueryText .= "WHERE maxentity.maxdt = d.dt;";

my %hResultData;

my $oDBH = DBI->connect("DBI:SQLite:dbname=$sDBFilePath", "", "", {RaiseError => 1, PrintError => 0, AutoCommit => 1}) 
	or respondQuit($DBI::errstr);

	eval{

		my $oSTH = $oDBH->prepare($sQueryText);
		$oSTH->execute();

		while(my $hrRow = $oSTH->fetchrow_hashref()){
			$hResultData{$hrRow->{'name'}}{VALUE} = $hrRow->{'value'};
			$hResultData{$hrRow->{'name'}}{CHECKIN} = $hrRow->{'checkin'};
			$hResultData{$hrRow->{'name'}}{DT} = $hrRow->{'dt'};
		}

		$oSTH->finish();

	};

	respondQuit($@) if $@;

$oDBH->disconnect();

print("Content-Type: text/html\r\n\r\n");
print("<html><head><title>list output</title></head><body><table><tr><td bgcolor='#c1c1a4'><b>name</b></td><td bgcolor='#c1c1a4'><b>value</b></td>");
print("<td bgcolor='#c1c1a4'><b>updated</b></td><td bgcolor='#c1c1a4'><b>checkin</b></td></tr>");
foreach my $sKey (keys(%hResultData)){

	my $sCheckinText = $hResultData{$sKey}{CHECKIN};
	my $sDTText = $hResultData{$sKey}{DT};

	print("<tr><td bgcolor='#eaeae1'>" . $sKey . "</td><td bgcolor='#eaeae1'>" . $hResultData{$sKey}{VALUE}. "</td>");
	print("<td bgcolor='#eaeae1'>" . $sDTText . "</td><td bgcolor='#eaeae1'>" . $sCheckinText . "</td></tr>");
}
print("</table></body></html>");




