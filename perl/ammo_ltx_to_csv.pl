use strict;
use warnings;
use lib;
use Readonly;
#use Data::Dumper qw(Dumper);

# ammo csv file
Readonly my $AMMO_CSV => "out\\ammo\\ammo.csv";

# save keys to csv file
my @ammo_keys = get_keys('ammo');
save_to_file($AMMO_CSV, '>', array_to_csv(@ammo_keys));

# parse files
foreach my $file (get_files('ammo')) {
	my %ammo = ();
	my $tag_key = q();
	open(FH, $file) or die "$!";
	while(<FH>) {
		next if is_garbage($_);
		chomp;
		$_ = clean($_);
		if (is_tag($_) and is_not_hud($_)) {
			$tag_key = $_;
			foreach my $ammo_key (@ammo_keys) {
				$ammo{$tag_key}{$ammo_key} = ',';
			}
			next;
		}
		foreach my $ammo_key (@ammo_keys) {
			if (defined $tag_key) {
				if ($ammo_key =~ /^ammo_section$/) {
					$ammo{$tag_key}{'ammo_section'} = $tag_key;
				}
				elsif (/^\$spawn/) {
					my $value = get_value($_);
					$ammo{$tag_key}{'$spawn'} = $value;
				}
				elsif (/^\$prefetch/) {
					my $value = get_value($_);
					$ammo{$tag_key}{'$prefetch'} = $value;
				}
				elsif (/^$ammo_key[\s{0,*}|=]/) {
					my $value = get_value($_);
					$ammo{$tag_key}{$ammo_key} = $value;
				}
			}
		}
	}
	close(FH);
	foreach my $key (sort keys %ammo) {
		if (is_not_ammo_tag($key)) {
			delete $ammo{$key};
			next;
		}
		my @ammo_values = ();
		foreach my $ammo_key (@ammo_keys) {
			push @ammo_values, $ammo{$key}{$ammo_key};
		}
		# save values to csv
		save_to_file($AMMO_CSV, '>>', array_to_csv(@ammo_values));
	}
#	print Dumper(%ammo);
}


