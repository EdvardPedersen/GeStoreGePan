#!/usr/bin/perl


use strict;
use Getopt::Std;
use List::Util qw[min max];


# Very simple tool to analyze timing data from the GePan framework

eval{
    _main();
};

if($@){
    print $@;
}


sub _main{
    print "USAGE: analyze_time_log.pl [PATH TO LOG FILES]\n";
    my $work_dir = $ARGV[0];
    my @work_dir_array = split('/', $work_dir);

    # The start time is the 2nd to last entry in the path
    my $start_time = @work_dir_array[-2];

    # Check if the directory supplied exists
    if( -d $work_dir){
        print STDOUT "Analyzing time logs for ".$work_dir."\n";
    } else {
        print STDOUT "Directory ".$work_dir." does not exist, exiting!";
        exit();
    }
    
    opendir(LOGDIR, $work_dir) || die "Can't open directory";

    my @timeLines;
    my @files = readdir(LOGDIR);

    #Read all the files in the path
    foreach my $file (@files){
        # Only open time log files
        if( $file =~ m/.time.log$/ ){
            open(LOGFILE, "<" . $work_dir . $file);
            while (my $line = <LOGFILE>) {
                # Add every entry in the file to the timeLines array
                if($line =~ m/start:/ || $line =~ m/stop:/) {
                  push(@timeLines, $line);
                }
            }
            close(LOGFILE);
        }
    }
    closedir(LOGDIR);

    if(scalar @timeLines < 1)
    {
        print "No log files found... Did you run GePan with performance evaluation on?\n";
        exit;
    }

    # Tools is a multidimensional hash table, the structure is such: $tools{tool_name}{start/stop}{time_since_pipeline_start}
    my %tools;

    # Populate %tools
    foreach my $line (@timeLines){
        my @tempLine = split(/ /, $line);
        push(@{$tools{@tempLine[0]}{substr(@tempLine[1], 0, -1)}}, int(@tempLine[2]) - int($start_time));
    }

    my $totalTimeTaken = 0;

    # Sort %tools by when they finish
    my @newsort = sort { int($tools{$a}{'stop'}[0]) <=> int($tools{$b}{'stop'}[0]) } keys %tools;

    foreach my $key (@newsort)
    {
#        print "key: " . $key . "\n";
        if($key eq "") {
          next;
        }
        my @timeStart = @{$tools{$key}{'start'}};
        my @timeStop = @{$tools{$key}{'stop'}};

        for my $i (0 ... min(scalar @timeStart, scalar @timeStop)){
            if($timeStart[$i] && $timeStop[$i]){
                my $timeTaken = int($timeStop[$i]) - int($timeStart[$i]);
                $totalTimeTaken += $timeTaken;
                print $key . " START: " . int($timeStart[$i]) . " STOP " . int($timeStop[$i]) . " Time taken " . $timeTaken . "\n";
            }
        }
    }

    my $resultDir = substr($work_dir, 0, length($work_dir) - 5) . "results/";

    opendir(RESULTDIR, $resultDir) || die "Can't open result directory";

    # Find the time of the final result(s)
    my @resultTimes;
    my @resultFiles = readdir(RESULTDIR);
    foreach my $resultFile (@resultFiles){
        if($resultFile !~ /^\./){
            my $modify_time = (stat($resultDir . $resultFile))[9];
            push (@resultTimes, int($modify_time));

        }
    }

    # $endTime is the timestamp of the most recently modified file in the results directory
    my $endTime = max @resultTimes;
    print "Pipeline started at " . $start_time . ", pipeline ended at " . $endTime . ".\n Wallclock time (seconds): " . ($endTime - $start_time) . 
          ", compute time (seconds): "  . $totalTimeTaken . ".\n"
}
