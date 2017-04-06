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

		open(my $fhOutput, ">>$sLogsPath/$$.update.out");
		print($fhOutput time() . " " . $sMessage . "\n");
		close($fhOutput);
	}

	print("<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1></body></html>");
	exit(0);
}


if(!defined($ENV{REQUEST_METHOD})){
	respondQuit("no method");
}
if($ENV{REQUEST_METHOD} ne "GET"){
	respondQuit("bad method");
}
if(!defined($ENV{QUERY_STRING})){
	respondQuit("no query");
}
if(length($ENV{QUERY_STRING}) != 68){ 
	respondQuit("bad query length");
}
if(!defined($ENV{HTTP_X_FORWARDED_FOR})){
	respondQuit("no x fwd address");
}

my $sKey = substr($ENV{QUERY_STRING}, 4, 64);
my $sNewValue = $ENV{HTTP_X_FORWARDED_FOR};

my $sTopValueQueryText = "SELECT d.value AS value ";
$sTopValueQueryText .= "FROM data d ";
$sTopValueQueryText .= "INNER JOIN (SELECT entity, max(dt) AS maxdt FROM data GROUP BY entity) AS maxentity ON maxentity.entity = d.entity ";
$sTopValueQueryText .= "INNER JOIN entity AS e ON e.id = d.entity ";
$sTopValueQueryText .= "WHERE maxentity.maxdt = d.dt ";
$sTopValueQueryText .= "AND e.id = ?;";

my $oDBH = DBI->connect("DBI:SQLite:dbname=$sDBFilePath", "", "", {RaiseError => 1, PrintError => 0, AutoCommit => 1}) 
	or respondQuit($DBI::errstr);

	eval{

		my $sSQL = "SELECT id FROM entity WHERE key = ?;";
		my $oSTH = $oDBH->prepare($sSQL);
		$oSTH->bind_param(1, $sKey);
		$oSTH->execute();

		my $hrRow = $oSTH->fetchrow_hashref();
		if(!defined($hrRow)){
			die("key not found");
		}
		my $iID = $hrRow->{'id'};
		$oSTH->finish();

		$oDBH->do("UPDATE entity SET checkin = CURRENT_TIMESTAMP WHERE id = ?", undef, $iID);

		$oSTH = $oDBH->prepare($sTopValueQueryText);
		$oSTH->bind_param(1, $iID);
		$oSTH->execute();

		my $sCurrentValue = undef;

		$hrRow = $oSTH->fetchrow_hashref();
		if(defined($hrRow)){
			$sCurrentValue = $hrRow->{'value'};
		}
		$oSTH->finish();

		if(!defined($sCurrentValue) || ($sCurrentValue ne $sNewValue)){
			$oDBH->do("INSERT INTO data (entity, dt, value) VALUES (?, current_timestamp, ?);", undef,
				$iID, $sNewValue);
		}

	};

	respondQuit($@) if $@;

$oDBH->disconnect();

respondQuit();


