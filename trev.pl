#!/usr/bin/env perl

# trev.pl - carries out taskwarrior task review.
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

use Term::ANSIColor;           # Color screen output using ANSI escape sequences
use Term::ReadLine;            # Perl interface to various readline packages.
use Term::ReadLine::Gnu;       # Perl extension for the GNU Readline/History Library.
#use Term::UI;                 # Term::ReadLine UI made easy
#use Term::ReadKey;        # MSWindows?
use File::Basename;
my $scriptdir = dirname(__FILE__);   # locating the script dir

#  Configuration > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > >
# -------------------------------------------------- Parameter hard-wired defaults
my $seltag    = "active";            # selection tag (fake, active is a report, not a tag)
my $on        = "start";             # select action
my $off       = "stop";              # unselect action
my $start     = -1;                  # starting task; initial value
my $filter    = "";
my $upper     = "";                  # upper label additional text                 
my $lower     = "";                  # lower label additional text                 

# -------------------------------------------------- Behavior and Appearance
my $L10N      = "eng-USA";
my $viewinfo  = "on";
my $showtime  = "on";
my $prompt    = "trev> ";
my $lblstyle  = "reverse bold";
my $sepstyle  = "underline bold";

#  < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < Configuration

# ------------------------------------------------------------------------ Allowed Actions
# These actions don't change the list of tasks (total number):
my @allow = (
    'annotate',    'append',  'denotate', 'edit',
    'information', 'log',     'prepend',  'start',
    'stop',        'version', 'calendar'
);

# These actions can change the list of tasks (total number):
my @allowch = ( 'add', 'delete', 'done', 'modify', 'duplicate','undo' );

# These actions don't need a task number in the command line:
my @nonumb = ( 'add', 'log', 'version', 'calendar' ,'undo' );

# ----------------------------------------------------------------------------------- L10N
                      # -------------------------------- eng-USA (default)
my $STRING_LBL_SEL = "Selected";
my $STRING_MSG_AMB = "is ambiguous, can be:";
my $STRING_MSG_END = "Finished.";
my $STRING_MSG_ERR = "Warning: not completed";
my $STRING_MSG_NFD = "Current and next tasks not found.";
my $STRING_MSG_NON = "\nNone\n\n";
my $STRING_MSG_QIT = "Terminated (task ";
my $STRING_MSG_RCN = "rc file not found, going with hard wired defaults.";
my $STRING_MSG_RCO = "Error opening rc file:";
my $STRING_MSG_RCC = "Erroneous construction in:";
my $STRING_MSG_RCP = "Unknown parameter in";
my $STRING_MSG_RET = "Press [RET] to continue: ";
my $STRING_MSG_STA = ": doesn't appear as visible.";
my $STRING_MSG_UND = "Not understood.";
my $STRING_MSG_TIM = "Running for ";
my $STRING_MSG_VER = "Taskwarrior version must be 2.2.0 at least.";
my $STRING_NOW_TXT = "Reviewing";
my $STRING_WRN_NUM = "Changed number of tasks! > ";
my $STRING_MSG_HLP = "Commands:   +                  Mark task\n" .
                     "            -                  Unmark task\n" .
                     "            -id                Unmark task [id]\n" .
                     "            [RET]              Move to next task\n" .
                     "            b                  Move back to previous task\n" .
                     "            ?, h[elp]          Display this help\n" .
                     "            q[uit], exit, bye  Exit\n\n" .
                     "Press [RET] to continue.\n";

# -------------------------------------------------------------- Taskwarrior Version check
my ( $major, $minor ) = split( /\./, `task --version` );
if ( $major < 2 || ($major == 2 && $minor < 2)) { goingout( "$STRING_MSG_VER\n" , 10 , "off" ); } # exit

# --------------------------------------------------------- Parsing command line arguments
# command line to parse: $ trev.pl [-t|-T text] [++seltag] [start+] [filter]
if ( scalar(@ARGV) != 0 ) {
    # ----------------------------------------------------------------- Options
    while ( scalar(@ARGV) && $ARGV[0] =~ m/\-(.)/ ) {
        shift( @ARGV ) ;
        my $opt = $1 ;
        if ( $opt eq 't' ) {
            $lower = $ARGV[0] ;
            shift( @ARGV ) ;
        }
        elsif ( $opt eq 'T' ) {
            $upper = $ARGV[0] ;
            shift( @ARGV ) ;
        }
        else {
            goingout( "-$1: $STRING_MSG_UND\n" , 20 , "off" );
        }
    }

    # ----------------------------------------------------------------- Arguments
    # if selection attribute requested: matches '++something'
    if ( scalar(@ARGV) && $ARGV[0] =~ m/\+\+(.+)/ ) {
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
            goingout( "$start$STRING_MSG_STA\n" , 20 , "off" );           # exit on error
        }
    }
    $filter = join( ' ', @ARGV );   # the rest of the line is considered filter
}

# -------------------------------------------------------------------------------- rc file
# -------------------------------------------------- locating the rc file (or none)
my $rcfilepath = "" ;
my $userhome = $ENV{"HOME"} ;
my @rcpaths  = ( "$userhome/.task/trevrc" , "$userhome/.trevrc" , "$scriptdir/trevrc" ) ;
foreach my $path ( @rcpaths ) {
    if ( -e $path ) {
        $rcfilepath = $path ;
        last ;
    }
}
if( $rcfilepath eq "" ) {
    print( "\nWarning: $STRING_MSG_RCN\n\n" ) ;
}
else {
    # ------------------------------------------------------- Reading rc
    open( IN , $rcfilepath ) ||
        goingout( "$STRING_MSG_RCO $rcfilepath\n" , 30 , "off" ) ;
    my @inlines = <IN> ;
    close IN ;

    # ------------------------------------------------------- Parsing rc
    # this way 'default' mode is always parsed (and parsed first) :
    my @modes     = ( "default" ) ;
    my $mode      = "" ;
    my $canbemode = "" ;
    if( $filter =~ m/(^\w+$)/ ) {         # single word
        $canbemode = $1 ;
    }
    # checking syntax and identifying requested modes:
    my @rclines = () ;
    foreach my $rcline ( @inlines ) {
        chomp( $rcline ) ;
        if( $rcline =~ m/^\s*$/ || $rcline =~ m/^\s*#/ ) { next } # blank lines & comments
        if( $rcline =~ m/^\s*review\.(\w+)\.(\w+)*\s*\=\s*(.*)$/ ) { # legal trevrc line
            push( @rclines , $rcline ) ;
            if( $mode eq "" && $1 eq $canbemode ) {
                $mode = $canbemode ;
                push( @modes , $canbemode ) ;
            }
        }
        else {
            goingout( "$STRING_MSG_RCC $rcfilepath: $rcline.\n" , 40 , 0 );# bad construct
        }
    }
    # reading parameters, first 'default' and then requested mode, if existing: 
    foreach my $mode ( @modes ) {
        foreach my $rcline ( @rclines ) {
            if( $rcline =~ m/^\s*review\.(\w+)\.(\w+)*\s*\=\s*(.*)$/ ) {
                if( $1 eq $mode ) {
                    my $param = $2 ;
                    my $value = $3 ;
                    $value =~ s/\s*$// ;
                    $value =~ s/^[\'|\"]// ; 
                    $value =~ s/[\'|\"]$// ; 
                    if(    $param eq "seltag"   ) { $seltag   = $value }
                    elsif( $param eq "on"       ) { $on       = $value }
                    elsif( $param eq "off"      ) { $off      = $value }
                    elsif( $param eq "filter"   ) { $filter   = $value }
                    elsif( $param eq "upper"    ) { $upper    = $value }
                    elsif( $param eq "lower"    ) { $lower    = $value }
                    elsif( $param eq "L10N"     ) { $L10N     = $value }
                    elsif( $param eq "viewinfo" ) { $viewinfo = $value }
                    elsif( $param eq "showtime" ) { $showtime = $value }
                    elsif( $param eq "prompt"   ) { $prompt   = $value }
                    elsif( $param eq "lblstyle" ) { $lblstyle = $value }
                    elsif( $param eq "sepstyle" ) { $sepstyle = $value }
                    else {
                        goingout( "$STRING_MSG_RCP $rcfilepath : $param\n" , 35 , 0 ) ;
                    }
                }
            }
        }
    }
    close IN ;
print "\ncanbemode: $canbemode\n\n" ; # DEBUG
print "L10N    : >$L10N<\n" ; # DEBUG
print "viewinfo: >$viewinfo<\n" ; # DEBUG
print "showtime: >$showtime<\n" ; # DEBUG
print "filter  : >$filter<\n" ; # DEBUG
print "seltag  : >$seltag<\n" ; # DEBUG
print "on      : >$on<\n" ; # DEBUG
print "off     : >$off<\n" ; # DEBUG
print "prompt  : >$prompt<\n" ; # DEBUG
print "upper   : >$upper<\n" ; # DEBUG
print "lower   : >$lower<\n" ; # DEBUG
print "lblstyle: >$lblstyle<\n" ; # DEBUG
print "sepstyle: >$sepstyle<\n\n" ; # DEBUG

#exit 0 ; # DEBUG
}

# ----------------------------------------------------------- L10N (non-default languages)
if( $L10N eq "esp-ESP" ) { # -------------------------------- esp-ESP
$STRING_LBL_SEL = "Seleccionadas";
$STRING_MSG_AMB = "es ambiguo, puede ser:";
$STRING_MSG_END = "Finalizado.";
$STRING_MSG_ERR = "Aviso: no se completa";
$STRING_MSG_NFD = "Tareas actual y siguiente no encontradas.";
$STRING_MSG_NON = "\nNinguna\n\n";
$STRING_MSG_QIT = "Terminado (tarea ";
$STRING_MSG_RCN = "fichero rc no encontrado, usando valores por defecto de script.";
$STRING_MSG_RCO = "Error abriendo el fichero rc:";
$STRING_MSG_RCC = "Construcción errónea en:";
$STRING_MSG_RCP = "Parámetro desconocido en";
$STRING_MSG_RET = "Presione [RET] para continuar. ";
$STRING_MSG_STA = ": no aparece como visible.";
$STRING_MSG_TIM = "Corriendo durante ";
$STRING_MSG_UND = "No comprendido.";
$STRING_MSG_VER = "Taskwarrior debe estar al menos en su versión 2.2.0 .";
$STRING_NOW_TXT = "Revisando";
$STRING_WRN_NUM = "¡Número de tareas cambiado! > ";
$STRING_MSG_HLP = "Commands:   +                  Marca la tarea\n" .
                  "            -                  Desmarca la tarea\n" .
                  "            -id                Desmarca la tarea [id]\n" .
                  "            [RET]              Continúa a la tarea siguiente\n" .
                  "            b                  Vuelve a la tarea previa\n" .
                  "            ?, h[elp]          Muestra esta ayuda\n" .
                  "            q[uit], exit, bye  Finaliza\n\n" .
                  "Presione [RET] para continuar.\n";
}

# ------------------------------------------------------------------ Term::Readline object
my $intime = 0 ;
if( $showtime eq "on" ) {
    $intime = time();                                     # Record time
}

my $term = Term::ReadLine->new('');
$term->ornaments(0);    # disable prompt default styling (underline)

#my %features = %{$term->Features};
#print "Features supported by ",$term->ReadLine,"\n";
#foreach (sort keys %features) { print "\t$_ => \t$features{$_}\n"; }; exit 0;

# ----------------------------------------------------------- Preparing Main loop Entrance
my $thisuuid;
my $nextuuid;
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

# ------------------------------------------------ Reporting about rc file
print( "\nUsing settings from: $rcfilepath\n" ) ;

# ------------------------------------- Identifying the clear-screen command
my $clearcommand = "clear" ;
if ( $^O eq 'cygwin' ) {
    $clearcommand = 'echo -e "\033[H\033[J"' ;
}
elsif ( $^O eq 'MSWin32' ) {
    $clearcommand = 'cls' ;
}

# ------------------------------------------------ viewinfo switch
my $postcommand = "" ;
if( $viewinfo eq "on" ) {
    $postcommand = " rc.verbose:off";
}
else {
    $postcommand = " rc.verbose:off list";
}

# ------------------------------------------------------------------------------ Main Loop
my $FLAGNTASKS = 0;                                 # flag: changed number of tasks
for ( my $i = $start ; $i <= $ntasks ; $i++ ) { # one more, for the final report
    my $line;
    my $curr = $tasks[$i];

    # ----------------------------------------------------------------- Terminal width
    my ( $rows, $cols ) = split( / /, `stty size` );    # Unix only
        # my ( $cols, $rows ,$p , $ph ) = GetTerminalSize( <STDOUT> ); # perhaps MSWindows
        # my ( $cols, $rows ) = GetTerminalSize( <STDOUT> ); # Unix & MSWindows?

    my $sep = my $uplbl = my $lowlbl = " " x ( $cols - 1 );         # base labels

    # ------------------------------------------------------------------- Progress bar
    my $progbar = $sep;
    my $progind = ( $i + 1 ) . "/" . $ntasks; # . " ";
    if (  $i == $ntasks ) {                 # past the last, final report
        $progind = ( $i ) . "/" . $ntasks ; # no advance, show the last
    }

    my $barmaxl = $cols - 8;
    my $percent = ( $i ) / $ntasks;
    my $bar     = "["
      . "=" x ( $barmaxl * $percent )
      . " " x ( $barmaxl * ( 1 - $percent ) ) . "]";
    my $progtxt = $bar . " " . int( 100 * $percent ) . "%";
    substr( $progbar, 0, length($progtxt) ) = $progtxt;
    system( $clearcommand ) ;
    print $progbar, "\n";

    # -------------------------------------------------------------------- Upper label
    my $uptxt = "$STRING_LBL_SEL ($seltag): $upper";     # upper label text
    substr( $uplbl, 1, length($uptxt) ) = $uptxt;
    print colored( $uplbl, $lblstyle ), "\n";

    # --------------------------------------------------------------- Reading selected
    my $sel = system("task rc.verbose:off $seltag");         # showing Selected tasks
    if ( $sel != 0 ) { print($STRING_MSG_NON ); }            # or none

    # -------------------------------------------------------------------- Lower label
    my $lowtxt = "$STRING_NOW_TXT $filter";
    $lowtxt = $lowtxt." ($progind): $lower";
    substr( $lowlbl, 1, length($lowtxt) ) = $lowtxt;
    print colored ( $lowlbl, $lblstyle ), "\n";              # lower label

    if (  $i == $ntasks ) {                       # past the last: final report done, exit
        goingout( "$STRING_MSG_END\n" , 0 , 1 );
    }
    else { 
        system("task $curr $postcommand");                   # the task to review
        print colored ( $sep, $sepstyle ), "\n";             # separating line
    }

    # ------------------------------------------------------------ Getting user input
    if( $FLAGNTASKS == 0 ) {
        $line = $term->readline( $prompt );
    }
    else {                           # number of tasks changed: issue prompt warning
        $line = $term->readline( $STRING_WRN_NUM );
        $FLAGNTASKS = 0                                      # reset flag
    }
   # $line = $term->get_reply( prompt => $prompt );   # error: needs up arrow twice

    # ---------------------------------------------------------------- Parsing Action
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
    elsif ( $line eq "?" || $line eq "h" || $line eq "help" ) {  # help request
        print $STRING_MSG_HLP;
        <STDIN>;
    }
    elsif ( $line eq "bye" || $line eq "q" || $line eq "quit" || $line eq "exit" ) {
        goingout( "$STRING_MSG_QIT$curr).\n" , 0 , $showtime );             # exit
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
        $thisuuid = `task $tasks[$i] _uuids`;       # get the uuid of this task
        if ( $i == $ntasks - 1 ) {                  # if this is the last task
            $nextuuid = "no-next-task";             # mark: no next task
        }
        else {
            $nextuuid = `task $tasks[$i+1] _uuids`; # get the uuid of the next task
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
        print($STRING_MSG_RET);
        <STDIN>;
        # ------------------------------------------------------------- Preparing Next
        # Actions that don't change the total number of tasks:
        if ( $FLAGCH == 0 ) {
            $i--; next;                             # proceeds with same (current) task
        }

        # Actions that can change the total number of tasks:
        my $FLAGFOUND = 0;                          # uuid found flag
        my @newtasks  = gettasks();
        my $nwtasks   = @newtasks;
        if( $nwtasks != $ntasks ){ $FLAGNTASKS = 1; } # set flag: changed number of tasks

        for ( my $k = 0 ; $k < $nwtasks ; $k++ ) {  # search current uuid in new list
            my $uuid = `task $newtasks[$k] _uuids`;
            if ( $uuid eq $thisuuid ) {
                $i = $k;                            # change index to new place
                $FLAGFOUND = 1;                     # present task uuid found in new list
                last;
            }
        }
        if ( $FLAGFOUND == 1 ) {
            @tasks = @newtasks;
            $ntasks = $nwtasks;
            $i--; next;                             # proceeds with same (current) task
        }
        elsif ( $nextuuid eq "no-next-task" ) {     # was the last and not found: exit
            goingout( "$STRING_MSG_END\n" , 0 , $showtime );
        }
        # current uuid not found and was not the last task:
        for ( my $k = 0 ; $k < $nwtasks ; $k++ ) {  # search next uuid in new list
            my $uuid = `task $newtasks[$k] _uuids`;
            if ( $uuid eq $nextuuid ) {
                $i = $k;                            # change index to new place
                $FLAGFOUND = 1;                     # present task uuid found in new list
                last;
            }
        }
        if ( $FLAGFOUND == 1 ) {
            @tasks = @newtasks;
            $ntasks = $nwtasks;
            $i--; next;                             # proceeds with next task
        }
        else {               # was not the last, not found and next not found: exit
            goingout( "$STRING_MSG_NFD\n" , 0 , $showtime );
        }
    }
}   # -------------------------------------------------------------------------- Main Loop
goingout( "$STRING_MSG_END\n" , 0 , $showtime );    # bye

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

# ----------------------------------------------------------------------------- goingout()
# goingout( $msg , $retval , $showtime );  does not return, exit function.
# -----------------------------------------------------------------------------
sub goingout {
    use integer;
    my $msg = shift; my $retval = shift; my $showtime = shift;

    print( $msg );
    if ( $showtime eq "on" ) {
        $_ = time() - $intime;
        my $s = $_ % 60; $_ /= 60;
        my $m = $_ % 60; $_ /= 60; $m = ($m == 0) ? "" : $m."m " ;
        my $h = $_ % 24; $_ /= 24; $h = ($h == 0) ? "" : $h."h " ;
        my $d = $_;                $d = ($d == 0) ? "" : $d."d " ;
        print ( $STRING_MSG_TIM.$d.$h.$m.$s."s\n" );
    }
    exit( $retval );
}
__END__
# -------------------------------------------------------------------------------- __END__
# See trev.pod for documentation

