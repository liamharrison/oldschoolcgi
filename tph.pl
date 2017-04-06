#!/usr/bin/perl

use warnings;
use strict;

use DBI;

our $sDBFilePath = "/var/www/files_lighttpd/tph/tph.db";

sub respondMessage(;$){

	my $sMessage = shift();

	print("Content-Type: text/html\r\n\r\n");
	print("<html><head><title>Message</title></head><body>");

	if(defined($sMessage)){
		print($sMessage);
	}else{
		print("OK");
	}

	print("</body></html>");
	
	exit(0);
}


if(!defined($ENV{REQUEST_METHOD})){
	respondMessage("no method");
}
if($ENV{REQUEST_METHOD} ne "GET"){
	respondMessage("bad method");
}
if(!defined($ENV{QUERY_STRING})){
	respondMessage("no query");
}

my $iNumberOfAMP = $ENV{QUERY_STRING} =~ tr/&//;
if($iNumberOfAMP != 2){
	respondMessage("bad query format AMP");
}

my @aKVPairs = split(/&/, $ENV{QUERY_STRING});
my %hParameters;

foreach my $sKVPair (@aKVPairs){

	if($sKVPair =~ /^[tph]=[0-9]+$/){

		my ($sKey, $iValue) = split(/=/, $sKVPair);
		$hParameters{$sKey} = $iValue;

	}else{

		respondMessage("bad query format KV");
	}
		
		

}

if(!defined($hParameters{'t'}) || !defined($hParameters{'p'}) || !defined($hParameters{'h'})){
	respondMessage("bad query format DEFINED");
}

my $oDBH = DBI->connect("DBI:SQLite:dbname=$sDBFilePath", "", "", {RaiseError => 1, PrintError => 0, AutoCommit => 1}) 
	or respondMessage($DBI::errstr);

	eval{

		$oDBH->do("INSERT INTO tph (time, t, p, h) VALUES (current_timestamp, ?, ?, ?);", undef,
			$hParameters{'t'}, $hParameters{'p'}, $hParameters{'h'});

	};

	respondMessage($@) if $@;

$oDBH->disconnect();

respondMessage();
