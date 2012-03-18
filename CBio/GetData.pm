package CBio::GetData;
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use WWW::Mechanize;
use XML::XPath;
use XML::XPath::XMLParser;

our $VERSION = "1.00";

sub new {
	my ($class,%args) = @_;

	my $self = bless({},$class);

	if (exists $args{target} && $args{target} ne ''){
		$self->{target} = $args{target};
	} else {
		$self->{target} = 'NAN';
	}

	return $self;
}

sub Run {
	my ($self) = @_;

	if ($self->{target} ne 'NAN'){
		print "Log> Input .. ".$self->{target}."\n";
		open(OT,"$self->{target}") || die "Log> Error Open $self->{target}\n";
		while(<OT>){
			chomp;

			my $entry = $_;

			print "Log> Process .. $entry\n";
			$self->Efetch($entry);
		}
	} else {
		print "Log> No Job Asssigned\n";
	}
}

sub Efetch {
	my ($self,$tar) = @_;

	my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=$tar&retmode=xml";
	my $w = WWW::Mechanize->new();

	$w->get($url);
	my $x = XMLin($w->{content});
}
