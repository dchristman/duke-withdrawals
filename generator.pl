#!/usr/bin/perl
# generator.pl by Dennis Christman at Duke University Libraries 2017
# designed to facilitate the creation of reports in the Aleph Reporting Center
# to ease the mass withdrawal of items from Aleph

use 5.22.1;
use warnings;
use IO::File;

my $library_code = "\"DUKR0\"";
my $bib_table = "\"DWH_DIM_BIB_INFO\"";
my $bib_docnumber_field = "\"DOC_NUMBER\"";
my $item_table = "\"DWH_FACT_ITEM\"";
my $item_barcode_field = "\"BAR_CODE\"";
my $item_docnumber_field = "\"DOCNUMBER\"";
my $item_processstatus_field = "\"PROCESS_STATUSID\"";
my $item_sublibrary_field = "\"SUBLIBRARYID\"";

my $ps_missing = "\'MI\'";
my $ps_lost = "\'LO\'";
my $ps_suppressed = "\'SU\'";
my $ps_withdrawn = "\'WI\'";
my $sl_ford = "\"FORD\"";
my $sl_law = "\"LAW\"";
my $sl_mcl = "\"MCL\"";

count_in_list();
check_missing();
check_nondul();
check_total();
say STDOUT 'Completed';

sub count_in_list{

  my ( $input, $output ) = file_init("barcodes.txt", "count-in-list.txt");

  my $out_string = "select $bib_table.$bib_docnumber_field\, count(*)
    from $library_code.$item_table $item_table
    inner join $library_code.$bib_table $bib_table on $bib_table.$bib_docnumber_field = $item_table.$item_docnumber_field
    where (";
  $out_string .= mass_concat($input, $item_table, $item_barcode_field);
  $out_string .= " group by $bib_table.$bib_docnumber_field";

  write_file ( $out_string , $output );
}

sub check_missing {
  my ( $input, $output ) = file_init("barcodes.txt", "check-missing.txt");

  my $out_string = "select $item_table.$item_barcode_field, $item_processstatus_field
    from $library_code.$item_table $item_table
    where ($item_table.$item_processstatus_field <> $ps_lost AND $item_table.$item_processstatus_field <> $ps_missing)
    AND ";

    $out_string .= mass_concat($input, $item_table, $item_barcode_field);

    write_file ($out_string, $output);

}

sub check_nondul {
  my ( $input , $output ) = file_init( "adm-numbers.txt", "check-nondul.txt");
  my $out_string = "select $bib_table.$bib_docnumber_field, count(*)
    from $library_code.$bib_table $bib_table
    inner join $library_code.$item_table $item_table on $bib_table.$bib_docnumber_field = $item_table.$item_docnumber_field
    where ($item_table.$item_processstatus_field <> $ps_suppressed AND $item_table.$item_processstatus_field <> $ps_withdrawn) AND ($item_table.$item_sublibrary_field  = $sl_ford OR $item_table.$item_sublibrary_field  = $sl_law OR $item_table.$item_sublibrary_field  = $sl_mcl)";
  $out_string .= mass_concat($input, $bib_table, $bib_docnumber_field);
  $out_string .= " group by $bib_table.$bib_docnumber_field";

  write_file ( $out_string , $output);
}

sub check_total {
  my ( $input , $output ) = file_init( "adm-numbers.txt", "check-total.txt");

  my $out_string = "select $bib_table.$bib_docnumber_field, count(*)
    from $library_code.$bib_table $bib_table
    inner join $library_code.$item_table $item_table on $bib_table.$bib_docnumber_field = $item_table.$item_docnumber_field
    where ($item_table.$item_processstatus_field <> $ps_suppressed AND $item_table.$item_processstatus_field <> $ps_withdrawn) AND ";

  $out_string .= mass_concat($input, $bib_table, $bib_docnumber_field);
  $out_string .= " group by $bib_table.$bib_docnumber_field";

  write_file ( $out_string , $output);
}

sub file_init {
  my ( $input_file , $output_file )= @_;
  my $input = IO::File->new("< $input_file") or die "Cannot open $input_file: $!";
  my $output = IO::File->new("> $output_file") or die "Cannot open $output_file: $!";
  return ( $input, $output );
}

sub file_close {
  close foreach (@_);
}

sub mass_concat {
  my ( $input , $table , $field ) = @_;

  my $out_string .= "($table.$field = \'" . <$input> . "\'";

  while (my $barcode = $input->getline()) {
    $out_string .= " or $table.$field = '$barcode'";
  };
  $out_string .= ")";
  return $out_string;
};

sub write_file {
  my ( $out_string , $output ) = @_;
  $out_string =~ s/[\r\n]//mg;
  $out_string =~ s/\s+/ /g;
  $output->print($out_string);
};
