#!/usr/bin/perl

# trev.pl - carries out taskwarrior tasks reviewing.
#
# Copyright 2013, Fidel Mato.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# http://www.opensource.org/licenses/mit-license.php

#  *************************************************************************************
#  * WARNING : Under developement, not production state. Watch your data: make backups *
#  *************************************************************************************

use strict;
use warnings;
use utf8;
binmode( STDOUT, ":utf8" );    # or use open ":utf8", ":std";

use Term::ANSIColor;      # Color screen output using ANSI escape sequences
use Term::ReadLine;       # Perl interface to various readline packages.
use Term::ReadLine::Gnu;  # Perl extension for the GNU Readline/History Library.
use Term::UI;             # Term::ReadLine UI made easy

# use Term::ReadKey;        # MSWindows?

# > > > > > > > > > > > > > > >  Configuration > > > > > > > > > > > > > > > > > > > > > >

# ------------------------------------------------------ selection and filter defaults
my $filter = "";

my $seltag = "active";    # selection tag (fake, active is a report, not a tag)
my $on     = "start";     # select action
my $off    = "stop";      # unselect action

#my $seltag = "+w";        # selection tag  , weekly review.
#my $on     = "mod +w";    # select action
#my $off    = "mod -w";    # unselect action

#my $seltag = "+someday";     # selection tag
#my $on     = "mod +someday"; # select action
#my $off    = "mod -someday"; # unselect action

# Uncomment STRINGs in your preferred localization ------------------------------ L10N
# ------------------------------------------------------------------------ en-US
my $STRING_LBL_SEL  = "Selected";
my $STRING_MSG_AMB  = "is ambiguous, can be:";
my $STRING_MSG_END  = "Finished.";
my $STRING_MSG_ERR  = "Warning: not completed";
my $STRING_MSG_NON  = "\nNone\n\n";
my $STRING_MSG_QIT  = "Terminated (task ";
my $STRING_MSG_RET  = "Press [RET] to continue: ";
my $STRING_MSG_STA  = ": doesn't appear as visible.";
my $STRING_MSG_UND  = "Not understood.";
my $STRING_MSG_TIM  = "Running for ";
my $STRING_MSG_VER  = "Taskwarrior version must be 2.2.0 at least.";
my $STRING_NOW_TXT  = "Now reviewing:";
# ------------------------------------------------------------------------ es-ES
#my $STRING_LBL_SEL = "Seleccionadas";
#my $STRING_MSG_AMB = "es ambiguo, puede ser:";
#my $STRING_MSG_END = "Finalizado.";
#my $STRING_MSG_ERR = "Aviso: no se completa";
#my $STRING_MSG_NON = "\nNinguna\n\n";
#my $STRING_MSG_QIT = "Terminado (tarea ";
#my $STRING_MSG_RET = "Presione [RET] para continuar: ";
#my $STRING_MSG_STA = ": no aparece como visible.";
#my $STRING_MSG_TIM = "Corriendo durante ";
#my $STRING_MSG_UND = "No comprendido.";
#my $STRING_MSG_VER = "Taskwarrior debe estar al menos en su versión 2.2.0 .";
#my $STRING_NOW_TXT = "Revisando ahora:";

# ------------------------------------------------------------------------ Appearance
my $prompt   = "trev> ";
my $lblstyle = "reverse bold";
my $sepstyle = "underline bold";

# < < < < < < < < < < < < < < <  Configuration < < < < < < < < < < < < < < < < < < < < < <

my $intime = time();                                                  # Record time

# ----------------------------------------------------------------------------- goingout()
# goingout( $msg , $retval , $showtime );  does not return, exit function.
# -----------------------------------------------------------------------------
sub goingout {
    use integer;
    my $msg = shift; my $retval = shift; my $showtime = shift;

    print( $msg );
    if ( $showtime == 1 ) {
        $_ = time() - $intime;
        my $s = $_ % 60; $_ /= 60;
        my $m = $_ % 60; $_ /= 60; $m = ($m == 0) ? "" : $m."m " ;
        my $h = $_ % 24; $_ /= 24; $h = ($h == 0) ? "" : $h."h " ;
        my $d = $_;                $d = ($d == 0) ? "" : $d."d " ;
        print ( $STRING_MSG_TIM.$d.$h.$m.$s."s\n" );
    }
    exit( $retval );
}

# -------------------------------------------------------------------------- Version check
my ( $major, $minor ) = split( /\./, `task --version` );
if ( $major < 2 || $minor < 2 ) { goingout( "$STRING_MSG_VER\n" , 10 , 0 ); } # exit

# ------------------------------------------------------------------ Term::Readline object
my $term = Term::ReadLine->new('');
$term->ornaments(0);    # disable prompt default styling (underline)

#my %features = %{$term->Features};
#print "Features supported by ",$term->ReadLine,"\n";
#foreach (sort keys %features) { print "\t$_ => \t$features{$_}\n"; }; exit 0;

# ------------------------------------------------------------------------ Allowed Actions
# These actions don't change the list of tasks (total number):
my @allow = (
    'annotate',    'append',  'denotate', 'edit',
    'information', 'log',     'prepend',  'start',
    'stop',        'version', 'calendar'
);

# These actions can change the list of tasks (total number):
my @allowch = ( 'add', 'delete', 'done', 'modify', );    # 'duplicate','undo'

# These actions don't need a task number in the command line:
my @nonumb = ( 'add', 'log', 'version', 'calendar' );

# ---------------------------------------------------------------------- Parsing arguments
my $start  = -1;

# command line to parse: $ perl trev.pl [++seltag] [start+] [filter]
if ( scalar(@ARGV) != 0 ) {
    # if selection attribute requested: matches '++something'
    if ( $ARGV[0] =~ m/\+\+(.+)/ ) {                     
        $seltag = "+$1";           # tag that will be used for selection
        $on     = "modify +$1";    # select action
        $off    = "modify -$1";    # unselect action
        shift(@ARGV);              # pulls $ARGV[0] out ; $ARGV[1] => $ARGV[0]
    }

    # if starting task number requested (matches 'digit(s)+'):
    if ( scalar(@ARGV) && $ARGV[0] =~ m/(\d+)\+/ ) {
        $start = $1;               # starting task number
        $filter =~ s/$start//;
        shift(@ARGV);              # pulls $ARGV[0] out ; $ARGV[1] => $ARGV[0]

        # check $start exists (and throwing STDOUT and STDERR)
        my $sysret = system("task $start rc.verbose:off >/dev/null 2>&1");

        # system() returns a false value on success, then:
        if ( $sysret != 0 ) {
            goingout( "$start$STRING_MSG_STA\n" , 20 , 0 );           # exit on error
        }
    }
    $filter = join( ' ', @ARGV );   # the rest of the line is considered filter
}

# ----------------------------------------------------------------------------- gettasks()
# @tasks = gettasks( );
# -----------------------------------------------------------------------------
sub gettasks {
    my @tasks;
    foreach my $line (`task $filter rc.verbose:off`) {
        if ( $line =~ /^\s{0,3}(\d+)/ ) { # digit(s) sequence after 1 to 3 blank spaces
            push( @tasks, $1 );
        }
    }
    return @tasks;
}

# ----------------------------------------------------------- Preparing Main loop Entrance
my $uuid;
my @tasks  = gettasks();
my $ntasks = scalar( @tasks );

# (Existence and visibility of requested start task has been already checked)
if ( $start > 0 ) {  # first arg numeric: start at this task number. Find order.
    for ( my $k = 0 ; $k < $ntasks ; $k++ ) {
        if ( $tasks[$k] == $start ) {
            $start     = $k;
            last;
        }
    }
}
if ( $start < 0 ) { $start = 0 }
for ( my $i = $start ; $i < $ntasks ; $i++ ) {   # ----------------------------- Main Loop
    my $line;
    my $curr = $tasks[$i];

    # -------------------------------------------------------- Terminal width & labels
    my ( $rows, $cols ) = split( / /, `stty size` );    # Unix only
        # my ( $cols, $rows ,$p , $ph ) = GetTerminalSize( <STDOUT> ); # perhaps MSWindows
        # my ( $cols, $rows ) = GetTerminalSize( <STDOUT> ); # Unix & MSWindows?
    my $sep = my $lbl = my $now = " " x ( $cols - 1 );
    my $lbltxt = "$STRING_LBL_SEL ($seltag):";
    substr( $lbl, 1, length($lbltxt) ) = $lbltxt;
    
    my $nowtxt = "($filter) $STRING_NOW_TXT";
    substr( $now, 1, length($nowtxt) ) = $nowtxt;

    # ------------------------------------------------------------------- Progress bar
    my $progbar = $sep;
    my $progind = ( $i + 1 ) . "/" . $ntasks . " ";
    my $barmaxl = $cols - length($progind) - 8;
    my $percent = ( $i + 1 ) / $ntasks;
    my $bar     = "["
      . "=" x ( $barmaxl * $percent )
      . " " x ( $barmaxl * ( 1 - $percent ) ) . "]";
    $progind = $progind . $bar . " " . int( 100 * $percent ) . "%";
    substr( $progbar, 0, length($progind) ) = $progind;
    system $^O eq 'MSWin32' ? 'cls' : 'clear';
    print $progbar, "\n", colored( $lbl, $lblstyle ), "\n";

    # --------------------------------------------------------------- Reading selected
    my $sel = system("task rc.verbose:off $seltag");         # showing Selected tasks
    if ( $sel != 0 ) { print($STRING_MSG_NON ); }            # or none
    print colored ( $now, $lblstyle ), "\n";                 # label Now reviewing:
    system("task $curr rc.verbose:off");                     # the Now-reviewing: task

    # ------------------------------------------------------- Getting & Parsing Action
    print colored ( $sep, $sepstyle ), "\n";                 # separating line
    $line = $term->get_reply( prompt => $prompt );           # getting user input (ui)
    if ( $line  ) { $line =~ s/^\s*//; $line =~ s/\s*$//; }  # strip blanks
    if ( !$line ) {                             # void line
        next;                                   # proceeds to next task
    }
    if ( $line eq "b" ) {                       # ui: go back
        $i = $i - 2;
        if ( $i < -1 ) { $i = -1 }              # no cycling back the start
        next;
    }
    elsif ( $line eq "+" ) {                    # ui: mark current task as selected
        system("task $curr $on");                   # (no warn if already selected)
        $i--; next;                             # proceeds with same (current) task
    }
    elsif ( $line eq "-" ) {                    # ui: mark current task as un-selected
        system("task $curr $off");                  # (no warn if not selected)
        $i--; next;                             # proceeds with same (current) task
    }
    elsif ( $line =~ m/^-(.*)/ ) {              # ui: '-' followed by some chars
        my $other = $1;
        if ( $other =~ m/^\d+$/ ) {             # at least 1 digit, and only digits
                system("task $other $off");     # unselect
                print "$STRING_MSG_RET";
                <STDIN>;                        # waiting for [RET]
        }
        else {                                  # not only digits after '-'
            print "$STRING_MSG_UND\n$STRING_MSG_RET";
            <STDIN>;
        }
        $i--; next;                             # proceeds with same (current) task
    }
    elsif ( $line eq "q" || $line eq "quit" || $line eq "exit" ) {  # quit request
        goingout( "$STRING_MSG_QIT$curr).\n" , 0 , 1 );             # exit
    }
    # ------------------------------------------------------------------ Command requested
    else {
        my ( $request, $args , $command );
        my @possibilities;
        my $FLAGCH = 2;         # flag: change number of tasks
        my $FLAGNN = 1;         # flag: need number of task

        $line =~ m/(\S+)/;      # first word (non-spaces)
        $request = $1;          # just the command - first word
        $line =~ s/$request//;  # strip request from $line
        $line =~ s/^\s*//;      # strip blanks
        $args = $line;

        # Search $request among actions that don't change the total number of tasks:
        foreach my $allow (@allow) {
            if ( index( $allow, $request ) == 0 ) {
                $FLAGCH = 0;    # flag: request will NOT change the number of tasks
                push( @possibilities, $allow );
            }
        }

        # Search $request among actions that can change the total number of tasks:
        foreach my $allowch (@allowch) {
            if ( index( $allowch, $request ) == 0 ) {
                $FLAGCH = 1;    # flag: request CAN change the number of tasks
                push( @possibilities, $allowch );
            }
        }
        if ( $FLAGCH == 2 ) {                       # No match in @allow nor in @allowch
            print("$STRING_MSG_UND\n$STRING_MSG_RET");
            <STDIN>;
            $i--; next;                             # proceeds with same (current) task
        }
        my $nposs = @possibilities;
        if ( scalar(@possibilities) > 1 ) {         # ambiguous: more than 1 possibility
            print( "'$request' $STRING_MSG_AMB ",
                join( '|', @possibilities ), "\n" );
            print($STRING_MSG_RET);
            <STDIN>;
            $i--; next;                             # proceeds with same (current) task
        }
        else {
            $command = $possibilities[0];
        }
        foreach my $nonumb (@nonumb) {              # needs a task number?
            if ( $command eq $nonumb ) {
                $FLAGNN = 0;
                last;
            }
        }

        # --------------------------------------------------------------------- Acting
        my $retval;
        if ( $i == $ntasks - 1 ) {                  # if this is the last task
            $uuid = "no-next-task";                 # mark: no next task
        }
        else {
            $uuid = `task $tasks[$i+1] _uuids`;     # get the uuid of the next task
        }
        if ( $FLAGNN == 1 ) {                       # does need a task number
            $retval = system("task $curr $command $args");
        }
        else {
            $retval = system("task $command $args");
        }
        if ( $retval != 0 ) {                       # system returned an error
            print("$STRING_MSG_ERR $command\n");
            print($STRING_MSG_RET);
            <STDIN>;
            $i--; next;                             # proceeds with same (current) task
        }
        # ------------------------------------------------------------- Preparing Next
        # Actions that don't change the total number of tasks:
        if ( $FLAGCH == 0 ) {
            $i--; next;                             # proceeds with same (current) task
        }

        # Actions that can change the total number of tasks:
        elsif ( $uuid eq "no-next-task" ) {
            goingout( "$STRING_MSG_END\n" , 0 , 1 );    # was the last: exit
        }
        else {
            my @newtasks = gettasks();
            $ntasks = @newtasks;
            for ( my $k = 0 ; $k < $ntasks ; $k++ ) {
                my $thisuuid = `task $newtasks[$k] _uuids`;
                if ( $thisuuid eq $uuid ) {
                    $i = $k - 1;
                    last;
                }
                    # FIXME implement not found => error, exit?
            }
            @tasks = @newtasks;
            next;
        }
    }
}   # -------------------------------------------------------------------------- Main Loop
goingout( "$STRING_MSG_END\n" , 0 , 1 );    # bye

__END__
# -------------------------------------------------------------------------------- __END__
# See trev.pod for documentation

