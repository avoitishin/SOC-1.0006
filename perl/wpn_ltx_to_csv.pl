use strict;
use warnings;
use lib;
use Readonly;
#use Data::Dumper qw(Dumper);

# TODO: add mechanism to differentiate between keys with the same name in main and hud sections

my $dir_name = get_path('wpn');
# ammo csv file
Readonly my $WPN_CSV => $dir_name."wpn.csv";

# save keys to csv file
my @wpn_keys = get_keys('wpn');
save_to_file($WPN_CSV, '>', array_to_csv(@wpn_keys));

# parse files
foreach my $file (get_files('wpn')) {
	my %wpn = ();
	my $tag_key = q();
	open(FH, $file) or die "$!";
	while(<FH>) {
		next if is_garbage($_);
		chomp;
		$_ = clean($_);
		if (is_tag($_) and is_not_hud($_)) {
			$tag_key = $_;
			foreach my $wpn_key (@wpn_keys) {
				$wpn{$tag_key}{$wpn_key} = ',';
			}
			next;
		}
		foreach my $wpn_key (@wpn_keys) {
			if (defined $tag_key) {
				if ($wpn_key =~ /^wpn_section$/) {
					$wpn{$tag_key}{'wpn_section'} = $tag_key;
				}
				elsif (!is_not_hud($_)) {
					$wpn{$tag_key}{'hud_section'} = $_;
				}
				elsif (/^\$npc/) {
					my $value = get_value($_);
					$wpn{$tag_key}{'$npc'} = $value;
				}
				elsif (/^\$spawn/) {
					my $value = get_value($_);
					$wpn{$tag_key}{'$spawn'} = $value;
				}
				elsif (/^\$prefetch/) {
					my $value = get_value($_);
					$wpn{$tag_key}{'$prefetch'} = $value;
				}
				elsif (/^visual/) {
					my $value = get_value($_);
					if ($wpn{$tag_key}{'hud_section'} eq ',') {
						$wpn{$tag_key}{'visual'} = $value;
					}
					else {
						$wpn{$tag_key}{'visual_1'} = $value;
					}
				}
				elsif (/^$wpn_key[\s{0,*}|=]/) {
					my $value = get_value($_);
					$wpn{$tag_key}{$wpn_key} = $value;
				}
			}
		}
	}
	close(FH);
	foreach my $key (sort keys %wpn) {
		my $file_name;
		if (is_not_wpn_tag($key)) {
			delete $wpn{$key};
			next;
		}
		else {
			$file_name = get_file_name_from_tag($key);
			unless(-d $dir_name.'\\'.$file_name) {mkdir $dir_name.'\\'.$file_name or die "$!";}
		}
		my $tmp_dir_name = $dir_name;
		$tmp_dir_name =~ s/\\$//;
		$wpn{$key}{'URL'} = $tmp_dir_name."\\".$file_name;
		my @wpn_values = ();
		foreach my $wpn_key (@wpn_keys) {
			my $value = q();
			if ($wpn_key eq 'description') {
				$value = build_desc("$wpn{$key}{'description'}", 'enc_weapons_', '', $dir_name.'\\'.$file_name, $file_name, '>', 1);
				$wpn{$key}{'description'} = $value;				
			}
			elsif ($wpn_key eq 'inv_name'){
				$value = build_desc("$wpn{$key}{'inv_name'}", 'inv_', '', $dir_name.'\\'.$file_name, $file_name, '>>', 1);
				$wpn{$key}{'inv_name'} = $value;				
			}
			elsif ($wpn_key eq 'inv_name_short'){
				$value = build_desc("$wpn{$key}{'inv_name_short'}", 'inv_', '_s', $dir_name.'\\'.$file_name, $file_name, '>>', 1);
				$wpn{$key}{'inv_name_short'} = $value;				
			}
			elsif ($wpn_key eq 'visual') {
				
			}
			push @wpn_values, $wpn{$key}{$wpn_key};
		}
		# save values to csv
		save_to_file($WPN_CSV, '>>', array_to_csv(@wpn_values));
	}
#	print Dumper(%wpn);
}
