package CBio::GetData;
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use WWW::Mechanize;

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
	my ($self,$tar,$db,$add) = @_;

	my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$db&id=$tar&retmode=xml&$add";
	my $w = WWW::Mechanize->new();

	$w->get($url);
	my $t = XMLin($w->{content});

  	$self->{multidata} = qw();

  	if (ref $t->{'GBSeq'} eq 'ARRAY'){
    	foreach(@{$t->{'GBSeq'}}){
      		if ($db eq 'protein'){
        		if ($_->{'GBSeq_moltype'} eq 'AA') {
          			my $qk = do_work($_);
          			$self->{multidata}{$qk->{Seq_Locus}} = $qk;
        		}
      		} else {
        		if ($_->{'GBSeq_moltype'} eq 'DNA' || $_->{'GBSeq_moltype'} eq 'mRNA') {
          			my $qk = do_work($_);
          			$self->{multidata}{$qk->{Seq_Locus}} = $qk;
        		}
      		}
    	}
  	} else {
    	my $qk = do_work($t->{'GBSeq'});
    	$self->{multidata}{$qk->{Seq_Locus}} = $qk;
  	}

  	sub do_work{
    	my ($k2) = @_;
   		my $sblf = {};

    	$k2->{'GBSeq_source-db'} =~ /^\S+: accession (\S+)$/;
    	$sblf->{source_db_id} = $1;  
    	$sblf->{Seq_Locus} = $k2->{'GBSeq_locus'};

    	$sblf->{def} = $k2->{'GBSeq_definition'};
    	$sblf->{organism} = $k2->{'GBSeq_organism'};

    	if (ref($k2->{'GBSeq_feature-table'}{'GBFeature'}) eq 'ARRAY'){

     		foreach(@{$k2->{'GBSeq_feature-table'}{'GBFeature'}}){
        		if ($_->{'GBFeature_key'} eq 'Protein'){
	      			$sblf->{from} = $_->{'GBFeature_intervals'}{'GBInterval'}{'GBInterval_from'};
	      			$sblf->{to} = $_->{'GBFeature_intervals'}{'GBInterval'}{'GBInterval_to'};
        		} elsif ($_->{'GBFeature_key'} eq 'gene'){
          			if (ref $_->{'GBFeature_quals'}{'GBQualifier'} eq 'ARRAY'){
            			foreach(@{$_->{'GBFeature_quals'}{'GBQualifier'}}){
              				if ($_->{'GBQualifier_value'} =~ /GeneID:(\S+)/) {
                				$sblf->{geneid} = $1;
              				} elsif ($_->{'GBQualifier_value'} =~ /MIM:(\S+)/) {
                				$sblf->{mim} = $1;
              				} elsif ($_->{'GBQualifier_name'} eq 'gene') {
                				$sblf->{gene_name} = $_->{'GBQualifier_value'};
              				} elsif ($_->{'GBQualifier_name'} eq 'gene_synonym') {
                				$sblf->{gene_syn} .= $_->{'GBQualifier_value'}."|";
              				} 
            			}
          			}  
        		} elsif ($_->{'GBFeature_key'} eq 'CDS'){
          			if (ref $_->{'GBFeature_intervals'}{'GBInterval'} eq 'ARRAY'){
            			foreach(@{$_->{'GBFeature_intervals'}{'GBInterval'}}){
              				push(@{$sblf->{cds_range}},
                      			{'cds_from'=>$_->{'GBInterval_from'},
                       			'cds_to'=>$_->{'GBInterval_to'}}
              				);  
            			}
            			if (ref $_->{'GBFeature_quals'}{'GBQualifier'} eq 'ARRAY'){
              				foreach(@{$_->{'GBFeature_quals'}{'GBQualifier'}}){
                				if ($_->{'GBQualifier_name'} eq 'translation'){
                  					$sblf->{translation} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'protein_id'){
                  					$sblf->{protein_Id} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'product'){
                  					$sblf->{protein_def} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'db_xref'){
                  					if ($_->{'GBQualifier_value'} =~ /GeneID:(\S+)/){
                    					$sblf->{GeneID} = $1;
                  					}
                				}
              				}
            			} else {
              				if ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'translation'){
                				$sblf->{translation} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'protein_id'){
                				$sblf->{protein_Id} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'product'){
                				$sblf->{protein_def} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'db_xref'){
                				if ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'} =~ /GeneID:(\S+)/){
                  					$sblf->{GeneID} = $1;
                				}
              				}
            			}
          			} else {
            			push(@{$sblf->{cds_range}},
                      		{'cds_from'=>$_->{'GBFeature_intervals'}{'GBInterval'}{'GBInterval_from'},
                       		'cds_to'=>$_->{'GBFeature_intervals'}{'GBInterval'}{'GBInterval_to'}}
            			);
            			if (ref $_->{'GBFeature_quals'}{'GBQualifier'} eq 'ARRAY'){
              				foreach(@{$_->{'GBFeature_quals'}{'GBQualifier'}}){
                				if ($_->{'GBQualifier_name'} eq 'translation'){
                  					$sblf->{translation} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'protein_id'){
                  					$sblf->{protein_Id} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'product'){
                  					$sblf->{protein_def} = $_->{'GBQualifier_value'};
                				} elsif ($_->{'GBQualifier_name'} eq 'db_xref'){
                  					if ($_->{'GBQualifier_value'} =~ /GeneID:(\S+)/){
                    					$sblf->{GeneID} = $1;
                  					}
                				}
              				}
            			} else {
              				if ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'translation'){
               					$sblf->{translation} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'protein_id'){
                				$sblf->{protein_Id} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'product'){
                				$sblf->{protein_def} = $_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'};
              				} elsif ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_name'} eq 'db_xref'){
                				if ($_->{'GBFeature_quals'}{'GBQualifier'}{'GBQualifier_value'} =~ /GeneID:(\S+)/){
                  					$sblf->{GeneID} = $1;
                				}
              				}
            			}
          			}
       			}
      		}
    	} else {

    	}
    	$sblf->{seq} = uc($k2->{'GBSeq_sequence'});
    	return $sblf;
  	}

  	my $has_data = 0;
  	while(my ($v1,$k1) = each %{$self->{multidata}}){
    	$has_data = length($k1->{seq});
  	}

	return $has_data;
}

sub GetAttr{
	my ($self,$type,$tar) = @_;

	if ($type eq 'cds_seq'){
		my $str = '';
    	foreach(@{$self->{multidata}{$tar}{cds_range}}){
      		$str .= substr($self->GetAttr('seq',$tar),$_->{'cds_from'}-1,$_->{'cds_to'}-$_->{'cds_from'}+1); 
    	}  
    	return $str;
  	} elsif ($type eq 'cds_from'){
    	if ($#{$self->{multidata}{$tar}{cds_range}} == 0){
      		return $self->{multidata}{$tar}{cds_range}->[0]->{'cds_from'};
    	} else {
      		my $ttmp = '';  
      		foreach(@{$self->{multidata}{$tar}{cds_range}}){
        		$ttmp .= "$_->{cds_from}|";
      		}
      		return $ttmp;
    	}
  	} elsif ($type eq 'cds_to'){
    	if ($#{$self->{multidata}{$tar}{cds_range}} == 0){
    		return $self->{multidata}{$tar}{cds_range}->[0]->{'cds_to'};
    	} else {
      		my $ttmp = '';  
      		foreach(@{$self->{multidata}{$tar}{cds_range}}){
        		$ttmp .= "$_->{cds_to}|";
      		}
      		return $ttmp;
    	}
  	} else {
    	return $self->{multidata}{$tar}{$type};
  	}
}

sub clean{
  my ($self) = @_;
  $self->{multidata} = ();
}
