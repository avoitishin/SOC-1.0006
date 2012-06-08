use strict;
use warnings;
require "lib.pm";

my $dir_name = get_file_name_from_tag("[wpn_ak74]");
unless(-d "out\\wpn\\$dir_name") {mkdir "out\\wpn\\$dir_name" or die "$!";}