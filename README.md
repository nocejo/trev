# NAME

trev.pl - taskwarrior tasks reviewing script

# SYNOPSIS

perl trev.pl [++mark] [start+] [filter]

# DESCRIPTION

trev is sort of a mini-shell focusing on taskwarrior reviewing.

This script reads a list of pending taskwarrior (http://taskwarrior.org/) tasks and presents them to the user one at a time, prompting for an action --among a restricted set of taskwarrior commands; this action (or none) is performed on the task, whereupon the script proceeds to the next task up to the end of the list.

At the script prompt the user can also include the current into a set of marked tasks which is continuously shown.  Tasks into this set are marked by taskwarrior as active or with a certain tag chosen by the user.

Tasks list comes from a system call to task, obeying then the user preferred settings for visibility, order, decoration...

# OPTIONS

Command line structure: after the script name two optional arguments (see below) can follow, ++mark and start+, in this order; then a serie of option/argument can follow; and finally, an optional filter argument closes the invocation.  Order is mandatory. 

## ARGUMENTS

No arguments are required.  Optional arguments can be issued to set a marking tag, a task number for the review to start and/or a taskwarrior filter.  Order is mandatory (see below).

- [++mark]

    If first argument starts with '++', as in 'trev.pl ++mark', the marking tag will be set to '+mark', marking action to 'modify +mark' and unmarking action to 'modify -mark'.  Double '+' is required in order to distinguish from a regular tag intended to be used as a filter.  If not set, default marking attribute is 'active', marking action is 'start' and unmarking action is 'stop' ('active' is not a taskwarrior tag but a report; this is not the more general case, which is intended to use a tag + modify).

- [start+]

    A numeric argument ending in '+' as in 'trev.pl 113+' , following an optional '++mark' and preceding any filter, requests the script to start reviewing at task number 113, and proceed to the end of the list.  This can be useful when resuming an interrupted long review.  Final '+' is required in order to distinguish from a just-one-task filter, like in 'trev.pl 113'.

- [filter]

    The rest of the line is taken as a taskwarrior filter --task number(s), report name, tag, bare term... see EXAMPLES below.  May be not all filters can be correctly interpreted.

    ## COMMAND LINE OPTIONS

- -T /Additional text/

    Adds 'Additional text' to the upper label, after 'Selected (mark): ', as a reminder or explanation.  Some characters (as !) have a significance for the shell and must be escaped (as \\!).

- -t /Additional text/

    Adds 'Additional text' to the upper label, after 'Reviewing filter (n/m): ', as a reminder or explanation.  Some characters (as !) have a significance for the shell and must be escaped (as \\!).

Argument/option order is mandatory: if a marking tag is specified it must be issued as the first argument; starting task number can be first (if no marking tag) or second (first is marking tag).  Filter must go at the end of the line.  Between arguments and filter options can be issued.

### EXAMPLES

See EXAMPLES below

## OPTIONS AT THE SCRIPT PROMPT

After displaying a progress bar, marked tasks and the current task, the script prompts for an action.  At this prompt you can issue this actions (entering them with [RET]):

- [RET]

    [RETURN] or void line.  No action.  Proceeds to the next task.

- b

    Goes back to the previous task.

- \+

    Marks task as 'active' (start-ing it, default) or with the requested marking tag.

- \-

    Unmarks current task and take it out of the 'marked' set.

- \-n

    If '-' is followed by a number, as in '-156', unmarks the referred task number, not to current.

- action [args]

    Executes a task action, Where allowed actions are: add, annotate, append, calendar, delete, denotate, done, duplicate, edit, information, log, modify, prepend, start, stop, undo and version.  Those that need a task number operate on the current task.  Can be shortened when not ambiguous.   Any action to perform on other task like in '175 delete' is not allowed.

- q, quit, exit, bye

    Terminate script execution.



# DEPENDENCIES

Taskwarrior 2.2.0+ must be installed.

Some needed modules ship with perl (as of 5.06): Term::ANSIColor and Term::ReadLine .  But some do not:

- Term::ReadLine::Gnu

    Perl extension for the GNU Readline/History Library.

You will need to install it from your distribution (this is libterm-readline-gnu-perl.deb package in debian-like) or get it from CPAN.

# CONFIGURATION

Defaults (mark and marking actions, prompt text, label and separator styles) can be modified directly in the Configuration section of the script source code.  Perl is an interpreted scripting language, so no compilation or building is needed.

Currently you can choose between two localizations: en-US and es-ES.  This is done in the L10N section of the source code, uncommenting the localized STRINGs in your preferred localization and commenting out the other set.

# EXAMPLES

- trev.pl

    Reviews all visible tasks (user default filter), starts reviewing at first of them (default), mark/unmark current task with start/stop (default).

- trev.pl ++week

    Set marking tag to +week and mark/unmark current task with 'modify +week'/'modify -week'.

- trev.pl ++calendula +ate\_loops

    Mark/unmark using 'modify +/-calendula'; Reviews only ate\_loops tagged tasks.

- trev.pl ++deleg 113+ pro:wp5

    Set marking tag to +deleg, start reviewing at task 113 and process only tasks appertaining to a certain wp5 project.

- trev.pl 113+ due:

    Processes only tasks without a due date.  Start at task 113.  Mark/unmark with start/stop and starts at the top of the list (defaults).

- trev.pl ++NOW overdue

    Processes overdue tasks.  Mark/unmark with 'modify +/-NOW'.

- trev.pl 113

    Reviews just task 113.  Start/stop for mark/unmark (default).

- trev.pl amsterdam

    Review every task containing amsterdam in its description, starting at the top of the list and marking/unmarking with start/stop.

- trev ++call -T 'Make these phone calls\\!' -t 'These are high-urgency actionable tasks\\!' urgency.over:12 +READY

    Review every task with an urgency.over:12 and marked +READY, starting at the top of the list and marking/unmarking with mod +call/-call.  'Make these phone calls!' and 'These are high-urgency actionable tasks!' appear respectively at the end of upper and lower labels.  Remark the necessary escaping \\! .





# FILES

No specific files are used, but the script issues system calls to 'task', and this is the expected name of the task executable. This can be modified inside the source code.

# CAVEATS

This is a slow script, specially when --after an action-- the order or number of tasks changes and next task must be located through its uuid.

In principle the script is intended to be used off-line, but if orders can come in any form from the web, beware: system calls are issued through backticks and any security check is performed.

# BUGS

Probably.



# AUTHOR

Fidel Mato <fidel.mato at gmail.com>.

# COPYRIGHT AND LICENSE

Copyright 2013, Fidel Mato

trev.pl is released under the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

http://www.opensource.org/licenses/mit-license.php

# DATE

8-Mar-2015
