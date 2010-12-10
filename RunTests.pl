#!/usr/bin/perl -w

use File::Compare;
use FileHandle;

system("perl CleanTests.pl");

my @failedTestFiles = ();

@testFileDirs = <Tests/*>;

foreach $testFileDir(@testFileDirs) {
    @testFileDir = <$testFileDir/*>;
    foreach $testFile(@testFileDir) {
        if($testFile =~ /\.next$/i) {
            #do the compilation
            $testFileDir =~ /(.+)\/(.+)/;
            if(system("./next < " . $testFile . " > " . $testFileDir . "/Next.java") == 0) {
                #do java compilation
                if(system("javac " . $testFileDir . "/Next.java") == 0) {
                    system("java -classpath " . $testFileDir . " Next > " . $testFileDir . "/output");
                }
            }
            
            #compare output with reference
            #if comparison returns 0 they are the same, otherwise they are not
            #write to log file of ones that are not
            if(File::Compare::compare_text($testFileDir . "/output", $testFileDir . "/reference")) {
                push(@failedTestFiles, $testFileDir);
            }

        }
    }
}


#write to log file
$fh = FileHandle -> new();
if($fh -> open("> Tests/FailedTests.txt")) {
    foreach $file(@failedTestFiles) {
        $fh -> print($file . "\n");
    }
}