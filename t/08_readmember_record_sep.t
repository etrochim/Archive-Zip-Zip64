use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;
use File::Spec;

use Test::More tests => 10;

BEGIN {
    unshift @INC, "t/"; 
    require( File::Spec->catfile('t', 'common.pl') )
		or die "Can't load t/common.pl";
}

{
    my $filename = File::Spec->catfile(TESTDIR, "member_read_xml_like1.zip");
    my $zip  = new Archive::Zip;
    # TEST
    isa_ok( $zip, "Archive::Zip", 
        "Testing that \$zip is an Archive::Zip"
    );

    my $data = <<"EOF";
One Line
Two Lines
</tag>
Three Lines
Four Lines
Five Lines
</tag>
Quant
Bant
</tag>
Zapta
EOF

    $zip->addString($data, "string.txt");
    $zip->writeToFileNamed($filename);

    {
        # Testing for normal line-based reading.
        my $member = $zip->memberNamed("string.txt");
        my $fh = $member->readFileHandle();

        # TEST
        ok ($fh, "Filehandle is valid");
        # TEST
        is ($fh->getline(), "One Line", 
            "Testing the first line in a normal read."
        );
        # TEST
        is ($fh->getline(), "Two Lines", 
            "Testing the second line in a normal read."
        );
    }
    
    {
        # Testing for setting the input record separator of the Perl
        # global variable.
        
        local $/ = "</tag>\n";

        my $member = $zip->memberNamed("string.txt");
        my $fh = $member->readFileHandle();

        # TEST
        ok ($fh, "Filehandle is valid");
        # TEST
        is ($fh->getline(), "One Line\nTwo Lines\n", 
            "Testing the first line in a normal read."
        );
        # TEST
        is ($fh->getline(), "Three Lines\nFour Lines\nFive Lines\n", 
            "Testing the second line in a normal read."
        );
    }

    {
        # Testing for setting input_record_separator in the filehandle.
        
        my $member = $zip->memberNamed("string.txt");
        my $fh = $member->readFileHandle();

        $fh->input_record_separator("</tag>\n");

        # TEST
        ok ($fh, "Filehandle is valid");
        # TEST
        is ($fh->getline(), "One Line\nTwo Lines\n", 
            "Testing the first line in a normal read."
        );
        # TEST
        is ($fh->getline(), "Three Lines\nFour Lines\nFive Lines\n", 
            "Testing the second line in a normal read."
        );
    }
}