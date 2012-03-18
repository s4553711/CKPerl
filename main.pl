#!/usr/bin/perl
use strict;
use CBio::GetData;

while ($#ARGV >= 0){
	my $jTyp = shift;

	if (lc($jTyp) eq 'getref'){
		my $input_file = shift || '';
		my $w = CBio::GetData->new( target => $input_file );
		$w->Run();
	} else {
		help();
	}
}

sub help{
	print "\nHelp> main.pl getref [input file]\n";
}
