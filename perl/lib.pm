use strict;
use warnings;
use File::Find;
use Readonly;

# constant: config path
Readonly my $GAME_PATH => "C:\\Users\\Andrey\\perl\\stalker\\";
Readonly my $CONFIG => $GAME_PATH."config\\";
Readonly my $OUT_WPN_PATH => "C:\\temp\\out\\wpn\\";
Readonly my $OUT_AMMO_PATH => "C:\\temp\\out\\ammo\\";
Readonly my $DESC_PATH => $CONFIG."text\\rus\\*.xml";
sub get_path {
	my($arg) = @_;
	if ($arg eq 'config') {return $CONFIG;}
	elsif ($arg eq 'wpn') {return $OUT_WPN_PATH;}
	elsif ($arg eq 'ammo') {return $OUT_AMMO_PATH;}
}

#my $PATH = "C:\\Users\\Andrey\\perl\\stalker\\config\\text\\rus\\*.xml";
my @enc_files = glob("$DESC_PATH");
sub build_desc {
	my($value,$prefix,$suffix,$dir_name,$item_name,$opt,$show_fname) = @_;
	my $found_path = q(Not found - using config values);
	my @lines_found;
	my $id = q();
	foreach my $file (@enc_files) {
		open (FH, $file) or die "$!";
		my $flag = 0;
		@lines_found = grep {$flag = $_ =~ /<string id=\"$value\">/ ? 1 : ($_ =~ /<\/string>/ ? 0 : $flag)} <FH>;
		shift @lines_found;
		close(FH);
		if (@lines_found) {
			$found_path = $file;
			$prefix = q();
			last;
		}
	}
	if (@lines_found) {
		my $text = otrim(array_to_string(@lines_found));
		$id = $value;
		my $line = q();
		if ($show_fname) {
			$line = qq($found_path\n<string id=\"$id\">\n$text\n<\/string>\n);
		}
		else {
			$line = qq(<string id=\"$id\">\n$text\n<\/string>\n);
		}
		save_to_file($dir_name.'\\'.$item_name.".xml",$opt, $line);
	}
	else {
		my $text = $value;
		$id = $prefix.$item_name.$suffix;
		my $line = q();
		if ($show_fname) {
			$line = qq($found_path\n<string id=\"$id\">\n<text>$text<\/text>\n<\/string>\n);
		}
		else {
			$line = qq(<string id=\"$id\">\n<text>$text<\/text>\n<\/string>\n);
		}
		save_to_file($dir_name.'\\'.$item_name.".xml",$opt, $line);
	}
	return $id;
}

# get keys from file
# parameters: key type (ammo, wpn, artifact, outfit)
Readonly my $AMMO_KEYS 	=> "in\\ammo_keys.txt";
Readonly my $WPN_KEYS 	=> "in\\wpn_keys.txt";
sub get_keys {
	my ($key_type) = @_;
	my @keys = ();
	if ($key_type eq 'ammo') {
		open(FH, $AMMO_KEYS) or die "$!";
		while(<FH>) {
			my $line = otrim($_);
			push @keys, $line;
		}
		close(FH);
		return @keys;
	}
	elsif ($key_type eq 'wpn') {
		open(FH, $WPN_KEYS) or die "$!";
		while(<FH>) {
			my $line = otrim($_);
			push @keys, $line;
		}
		close(FH);
		return @keys;
	}
	else {
		die "Invalid key type: $key_type";
	}
	return @keys; 
}

# get file name from tag ([wpn_ak74]:identity_immunities -> wpn_ak74.ltx)
sub get_file_name_from_tag {
	my($tag,$ext) = @_;
	if (is_tag($tag) and is_not_hud($tag)) {
		$tag =~ /^\[(.*)\]/;
		if ($ext) {
			return $1.'.'.$ext;
		}
		else {
			return $1;
		}
	}
	else {
		die "Please enter a valid tag";
	}
}

# save to file
# parameters:
# 1. file name
# 2. option - new file or append (>, >>)
# 3. text
sub save_to_file {
	my($file_name, $opt, $text) = @_;
	open(FH, $opt, $file_name) or die "$!";
		print FH $text;
	close(FH);
}

# convert array to string
sub array_to_string {
	my @array = @_;
	my $string = q();
	for (@array) {
		$string .= $_;
	}
	return $string;
}

# convert array to csv line
sub array_to_csv {
	my @array = @_;
	my $csv = q();
	for (@array) {
		if (m/^,/) {
			$csv .= ',';
		}
		else {
			$csv .= $_.",";
		}
	}
	$csv =~ s/,$/\n/;
	return $csv;
}

# convert csv line to array
sub csv_to_array {
	my($csv) = @_;
	my @array = split(/,/, $csv);
	return @array;
}

# convert unix path to windows path
sub fix_path {
	my $path = shift;
	$path =~ tr!/!\\!;
	return $path;
}

# return list of files of specified type
# parameters: file type (ammo, wpn, artifact, outfit)
my @file_list;
my $full_path;
sub get_files {
	my($file_type) = @_;
	@file_list = ();
	if ($file_type eq 'ammo') {
#		push @file_list, $CONFIG."weapons\\weapons.ltx";
		sub ammo_wanted {
			$full_path = fix_path($File::Find::name);
#			if ($full_path =~ m/weapons\\Arsenal_Mod\\Ammo\\.*.ltx$/) {
			if (m/.*.ltx$/) {
				push @file_list, $full_path;
			}
		}
		find(\&ammo_wanted, $CONFIG."weapons");
		return @file_list;
	}
	elsif ($file_type eq 'wpn') {
#		push @file_list, $CONFIG."weapons\\weapons.ltx";
		sub wpn_wanted {
			$full_path = fix_path($File::Find::name);
			if ($full_path =~ m/weapons\\w_.*.ltx$/) {
				push @file_list, $full_path;
			}
			elsif ($full_path =~ m/weapons\\Arsenal_Mod\\AR\\.*.ltx$/) {
				push @file_list, $full_path;
			}
			elsif ($full_path =~ m/weapons\\Arsenal_Mod\\LMG\\.*.ltx$/) {
				push @file_list, $full_path;
			}
			elsif ($full_path =~ m/weapons\\Arsenal_Mod\\SR\\.*.ltx$/) {
				push @file_list, $full_path;
			}
			elsif ($full_path =~ m/misc\\unique_items.ltx$/) {
				push @file_list, $full_path;
			}
		}
		find(\&wpn_wanted, $CONFIG);
		return @file_list;
	}
	elsif ($file_type eq 'artifact') {
		
	}
	elsif ($file_type eq 'outfit') {
		
	}
	else {
		die "Invalid file type: $file_type";
	}
}

# will remove the following:
#  - comments (;)
#  - whitespaces
#  - dashes (--)
sub clean {
	my($line) = @_;
	if (defined $line) {
		my @comments = split(/;/, $line);
		my @dashes = split(/--/, $comments[0]);
		$line = otrim($dashes[0]);
		return $line;
	}
	else {
		return q();
	}
}

# get key from line
sub get_key {
	my($line) = @_;
	my @keys = split(/=/, $line);
	my $key = otrim($keys[0]);
	return $key;
}

# get value from line and fix quotes
sub get_value {
	my($line) = @_;
	my @values = split(/=/, $line);
	my $value = otrim($values[1]);
	if ($value eq '0') {
		$value = '0';
	}
	elsif (!$value) {
		$value = ',';
	}
	elsif ($value =~ /^"/) {
		my @quotes = split(/"/, $value);
		$value = '"'.$quotes[1].'"';
	}
	elsif ($value =~ m/^[^,]/) {
		$value =~ s/,/; /g;
	}
	return $value;
}

# check if the line starts with tag ([])
# parameters:
# 1. line
# 2. specific tag - optional
sub is_tag {
	my($line,$tag) = @_;
	if (defined $tag) {
		return $line =~ m{^\[$tag.*\]}x;
	}
	else {
		return $line =~ m{^\[.*\]}x;	
	}
}

# return false if tag is a hud tag
sub is_not_hud {
	my ($line) = @_;
	if (defined $line) {
		if ($line =~ m/\[.*_hud([0-9]*)\]/) {
			return 0;
		}
	}
	return 1;
}

# return true if tag is:
# 1. - [bolt]
# 2. - [grenade.*]
# 3. - [ammo.*]
# 4. - [yadrena_*]
# 5. - [*_ves*]
# 6. - [*_otdaca*]
# 7. - [*_kalibr*]
# 8. - [*outfit*]
# 9. - [*_upgrade_*]
# 10.- [*_arena]
sub is_not_wpn_tag {
	my($tag) = @_;
	if ($tag =~ /^(\[bolt\]|\[grenade.*\]|\[ammo.*\]|\[yadrena_.*\].*|\[.*_ves.*\]|\[.*_otdaca.*\]|\[.*_kalibr.*\]|\[.*outfit.*\]|\[.*_upgrade_.*\]|\[.*_arena\])/) {
		return 1;
	}
	return 0;
}

# return true is tag is not [ammo_*] and
# 1. - [ammo_base]
# 2. - [*_foto]
sub is_not_ammo_tag {
	my($tag) = @_;
	if ($tag =~ /^(\[ammo_base\]|\[.*_foto\])/) {
		return 1;
	}
	elsif ($tag =~ /^\[ammo_.*\]/) {
		return 0;
	}
	return 1;
}

# returns true if line starts with letter or [ or $
# parameters - line
sub is_not_garbage {
	my($line) = @_;
	if ($line =~ /^([a-zA-Z]|\[|\$)/) {
		return 1;
	}
	return 0;
}

# returns false if line starts with letter or [ or $
# parameters - line
sub is_garbage {
	my($line) = @_;
	if ($line =~ /^([a-zA-Z]|\[|\$)/) {
		return 0;
	}
	return 1;
}

# outside trim - remove whitespaces from outside of string
# parameters - line to trim
sub otrim {
	my($line) = @_;
	$line = ltrim($line);
	$line = rtrim($line);
	return $line;
}

# left trim - remove whitespaces from left of string
# parameters - line to trim
sub ltrim {
	my($line) = @_;
	if (defined $line) {
		$line =~ s/^\s+//;
		return $line;
	}
	else {
		return q();
	}
}

# right trim - remove whitespaces from right of string
# parameters - line to trim
sub rtrim {
	my($line) = @_;
	if (defined $line) {
		$line =~ s/\s+$//;
		return $line;
	}
	else {
		return q();
	}
}

1;