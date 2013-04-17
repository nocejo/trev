#!/usr/bin/perl
# trev.pl

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
my $prompt   = "trev> ";
my $lblstyle = "reverse bold";
my $sepstyle = "underline bold";

# Uncomment STRINGs in your preferred localization ---------------------------------- L10N
# ---------------------------------------------------------------------------------- en-US
my $STRING_LBL_SEL  = "Selected:";
my $STRING_MSG_AMB  = "is ambiguous, can be:";
my $STRING_MSG_END  = "Finished.";
my $STRING_MSG_ERR  = "Warning: not completed";
my $STRING_MSG_NON  = "\nNone\n\n";
my $STRING_MSG_QIT  = "Terminated (task ";
my $STRING_MSG_RET  = "Press [RET] to continue: ";
my $STRING_MSG_STA  = ": doesn't appear as visible.";
my $STRING_MSG_UND  = "Not understood.";
my $STRING_MSG_VER  = "Taskwarrior version must be 2.2.0 at least.";
my $STRING_NOW_TXT  = "Now reviewing:";
# ---------------------------------------------------------------------------------- es-ES
#my $STRING_LBL_SEL = "Seleccionadas:";
#my $STRING_MSG_AMB = "es ambiguo, puede ser:";
#my $STRING_MSG_END = "Finalizado.";
#my $STRING_MSG_ERR = "Aviso: no se completa";
#my $STRING_MSG_NON = "\nNinguna\n\n";
#my $STRING_MSG_QIT = "Terminado (tarea ";
#my $STRING_MSG_RET = "Presione [RET] para continuar: ";
#my $STRING_MSG_STA = ": no aparece como visible.";
#my $STRING_MSG_UND = "No comprendido.";
#my $STRING_MSG_VER = "Taskwarrior debe estar al menos en su versión 2.2.0 .";
#my $STRING_NOW_TXT = "Revisando ahora:";

# ---------------------------------------------------------- selection and filter defaults
my $selatt = "active";    # selection attribute
my $on     = "start";     # select action
my $off    = "stop";      # unselect action
my $filter = "";

# < < < < < < < < < < < < < < <  Configuration < < < < < < < < < < < < < < < < < < < < < <

# -------------------------------------------------------------------------- Version check
my ( $major, $minor ) = split( /\./, `task --version` );
if ( $major < 2 || $minor < 2 ) { print "$STRING_MSG_VER\n"; exit(1); }

my $term = Term::ReadLine->new('');
$term->ornaments(0);    # disable prompt default styling (underline)

#my %features = %{$term->Features};
#print "Features supported by ",$term->ReadLine,"\n";
#foreach (sort keys %features) { print "\t$_ => \t$features{$_}\n"; }; exit 0;

# ------------------------------------------------------------------------ Allowed Actions
# These actions don't change the total number of tasks:
my @allow = (
    'annotate',    'append',  'denotate', 'edit',
    'information', 'log',     'prepend',  'start',
    'stop',        'version', 'calendar'
);

# These actions can change the total number of tasks:
my @allowch = ( 'add', 'delete', 'done', 'modify', );    # 'duplicate','undo'

# These actions don't need a task number in the command line:
my @nonumb = ( 'add', 'log', 'version', 'calendar' );

# ---------------------------------------------------------------------- Parsing arguments
my $start  = -1;

if ( scalar(@ARGV) != 0 ) {
    if ( $ARGV[0] =~ m/\+\+(.+)/ )
    {                     # selection attribute requested: matches '++some'
        $selatt = "+$1";           # selection attribute
        $on     = "modify +$1";    # select action
        $off    = "modify -$1";    # unselect action
        shift(@ARGV);              # pulls $ARGV[0] out ; $ARGV[1] => $ARGV[0]
    }

    # if starting task number requested (matches 'digit(s)+'):
    if ( scalar(@ARGV) && $ARGV[0] =~ m/(\d+)\+/ ) {
        $start = $1;
        $filter =~ s/$start//;
        shift(@ARGV);              # pulls $ARGV[0] out ; $ARGV[1] => $ARGV[0]

        # check $start exists (and throwing STDOUT and STDERR)
        my $sysret = system("task $start rc.verbose:off >/dev/null 2>&1");

        # system() returns a false value on success, then:
        if ( $sysret != 0 ) {
            print "$start$STRING_MSG_STA\n";
            exit(2);               # exit on error
        }

    }
    $filter = join( ' ', @ARGV );
}

# ----------------------------------------------------------------------------- gettasks()
sub gettasks() {
    my @tasks;
    foreach my $line (`task $filter rc.verbose:off`) {
        if ( $line =~ /^\s{0,3}(\d+)/ ) {
            push( @tasks, $1 );
        }
    }
    return @tasks;
}

# ----------------------------------------------------------- Preparing Main loop Entrance
my $uuid;
my @tasks  = gettasks();
my $ntasks = scalar(@tasks);

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
    substr( $lbl, 1, length($STRING_LBL_SEL) ) = $STRING_LBL_SEL;
    substr( $now, 1, length($STRING_NOW_TXT) ) = $STRING_NOW_TXT;

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
    my $sel = system("task $filter rc.verbose:off $selatt"); # showing Selected tasks
    if ( $sel != 0 ) { print($STRING_MSG_NON ); }            # or none
    print colored ( $now, $lblstyle ), "\n";                 # label Now reviewing:
    system("task $curr rc.verbose:off");                     # the Now-reviewing: task

    # ------------------------------------------------------- Getting & Parsing Action
    print colored ( $sep, $sepstyle ), "\n";                 # separating line
    $line = $term->get_reply( prompt => $prompt );           # getting user input (ui)
    if ( $line  ) { $line =~ s/^\s*//; $line =~ s/\s*$//; }  # blanks out
    if ( !$line ) {                             # void line
        next;
    }
    if ( $line eq "b" ) {                       # ui: go back
        $i = $i - 2;
        if ( $i < -1 ) { $i = -1 }              # no cycling back the start
        next;
    }
    elsif ( $line eq "q" ) { # add:|| $line eq "quit" || $line eq "exit" || $line eq "bye" 
        print "$STRING_MSG_QIT$curr).\n";
        exit(0);
    }
    elsif ( $line eq "+" ) {                    # ui: mark current task as selected
        system("task $curr $on");
        next;
    }
    elsif ( $line eq "-" ) {                    # ui: mark current task as un-selected
        system("task $curr $off");
        $i--;
        next;
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
        $i--; next;                             # follow with same current task
    }
    else {
        my ( $command, $comm, $args );
        my @possibilities;
        my $FLAGCH = 2;    # flag: change number of tasks
        my $FLAGNN = 1;    # flag: need number of task

        $line =~ m/(\S+)/;
        $comm = $1;
        $line =~ s/$comm//;
        $args = $line;
        $line =~ s/^\s*//;    # blanks
        # Actions that don't change the total number of tasks:
        foreach my $allow (@allow) {
            if ( index( $allow, $comm ) == 0 ) {
                $FLAGCH = 0;
                push( @possibilities, $allow );
            }
        }

        # Actions that can change the total num of tasks:
        foreach my $allowch (@allowch) {
            if ( index( $allowch, $comm ) == 0 ) {
                $FLAGCH = 1;
                push( @possibilities, $allowch );
            }
        }
        if ( $FLAGCH == 2 ) {    # No match
            print("$STRING_MSG_UND\n$STRING_MSG_RET");
            <STDIN>;
            $i--;
            next;
        }
        my $nposs = @possibilities;
        if ( scalar(@possibilities) > 1 ) {    # ambiguous
            print( "'$comm' $STRING_MSG_AMB ",
                join( '|', @possibilities ), "\n" );
            print($STRING_MSG_RET);
            <STDIN>;
            $i--;
            next;
        }
        else {
            $command = $possibilities[0];
        }
        foreach my $nonumb (@nonumb) {
            if ( $command eq $nonumb ) {
                $FLAGNN = 0;
                last;
            }
        }

        # --------------------------------------------------------------------- Acting
        my $retval;
        $uuid =
          `task $tasks[$i+1] _uuids`;    # !!!!!!!!!!!!!!!!!!!!!! warning: last
        if ( $FLAGNN == 1 ) {
            $retval = system("task $curr $command $args");
        }
        elsif ( $FLAGNN == 0 ) {
            $retval = system("task $command $args");
        }
        if ( $retval != 0 ) { print("$STRING_MSG_ERR $command\n"); }
        print($STRING_MSG_RET);
        <STDIN>;

        # ------------------------------------------------------------- Preparing Next
        # Actions that don't change the total number of tasks:
        if ( $FLAGCH == 0 ) {
            $i--;
            next;
        }

        # Actions that can change the total number of tasks:
        elsif ( $FLAGCH == 1 ) {
            my @newtasks = gettasks();
            $ntasks = @newtasks;
            for ( my $k = 0 ; $k < $ntasks ; $k++ ) {
                my $thisuuid = `task $newtasks[$k] _uuids`;
                if ( $thisuuid eq $uuid ) {

                    # !!!!!!! implement not found => error, exit?
                    $i = $k - 1;

                    # !!!!!!!!!!!!!!!!!!!!!!!!!!! Implementar: last -> first
                    last;
                }
            }
            @tasks = @newtasks;
            next;
        }
    }
}   # -------------------------------------------------------------------------- Main Loop
print "$STRING_MSG_END\n";    # bye
exit(0);
__END__
# -------------------------------------------------------------------------------- __END__
# See ./trev.pod for documentation

