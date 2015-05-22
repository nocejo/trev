# NAME

trev.pl - Taskwarrior review

# SYNOPSIS

perl trev.pl \[-t|T\] \[++mark\] \[start+\] \[filter\]

# DESCRIPTION

This perl script reads a list of taskwarrior (http://taskwarrior.org/) tasks and presents them to the user one at a time, prompting for an action --among a restricted set of taskwarrior commands; issued action (or none) is performed on the task, whereupon the script proceeds to the next task up to the end of the list.  Take into account that actions issued by the user, as well as other events, can alter the list along the review process, so after every potentially changing action the list is re-read. 

At the script prompt the user can also include the current into a set of marked tasks which is continuously shown.  Tasks into this set are marked/unmarked by default as active/stopped, but the marking tag can be modified by the user as an option at the command line or pre-configured in the configuration file.

Apart from specifying options, marks, filters in the command line call to the script, a *named review* can be issued, as in `$ trev calls` --referring to one of the named reviews defined in the configuration file-- provoking a pre-configured review, single or cascaded; see CONFIGURATION and FILES.

Tasks lists come from system calls to taskwarrior, obeying then the user preferred settings for visibility, order, decoration...

# OPTIONS/ARGUMENTS

Command line structure: after the script name a number of option/argument (e.g.: -T 'Make these calls!') can follow; then two optional arguments (see below) can follow, ++mark and start+, in this order; and finally, an optional filter argument closes the invocation.  Order is mandatory. 

No options/arguments are required.  Options to set additional text in upper and/or lower labels con be issued. Optional arguments can be issued to set a marking tag, a task number for the review to start and/or a taskwarrior filter.  Order is mandatory (see below).

## COMMAND LINE OPTIONS

- `\-T 'Additional text'` , `\-t 'Additional text'` 

Add 'Additional text' to the upper (-T) or lower (-t) label, as a reminder or explanation.  Quotation marks are required if text contains blank spaces.

## ARGUMENTS

- \[++mark\]

    If first argument after options starts with '++', as in `trev.pl ++mark`, the marking tag will be set to '+mark', marking action to `modify +mark` and unmarking action to `modify -mark`.  Double '+' is required in order to distinguish from a regular tag intended to be used as a filter.  If not set, default marking attribute is 'active', marking action is 'start' and unmarking action is 'stop' ('active' is not a taskwarrior tag but a report; this is not the more general case, which is intended to use a tag + `modify`).

- \[start+\]

    A numeric argument ending in '+' as in `trev.pl 113+` , following an optional '++mark' and preceding any filter, requests the script to start reviewing at task number 113, and proceed to the end of the list.  This can be useful when resuming an interrupted long review.  Final '+' is required in order to distinguish from a just-one-task filter, like in `trev.pl 113`.

- \[filter\]

    The rest of the line is taken as a taskwarrior filter --task number(s), report name, tag, dates, bare term... see EXAMPLES below.  May be not all filters can be correctly interpreted.

Argument/option order is mandatory: option(s) must come first, if at all issued. If a marking tag is specified it must be issued as the first argument following options; starting task number can be first (if no marking tag) or second (first is marking tag) after options.  Filter must go at the end of the line.

### EXAMPLES

See EXAMPLES below

## OPTIONS AT THE SCRIPT PROMPT

After clearing the console, displaying a progress bar, an upper, separating label, the set of currently marked tasks, a lower, separating label and the current task, the script prompts for an action.  At this prompt the following actions can issued (entering them with \[RET\]):

- \[RET\] (void line)

    No action: proceeds to the next task.

- b

    Goes back to the previous task.

- \+

    Marks task as 'active' (start-ing it, default) or with the pre-configured or requested marking tag.

- \-

    Unmarks current task and take it out of the 'marked' set.

- \-n

    If '-' is followed by a number, as in `-156`, unmarks the referred task number, not the current.

- taskwarrior command \[args\]

    Executes an allowed taskwarrior action, being allowed actions:

    -`annotate, append, delete, denotate, done, duplicate, edit, information, modify, prepend, start, stop`

    -`add, calendar, log, undo, version`

    Those taskwarrior commands that need a task number (first group) operate on the current task.  Commands can be shortened when not ambiguous.   Any command to perform on other --not the current-- task like in `175 delete` (when e.g.: 37 is the current one) is not allowed.

- q, quit, exit, bye

    Terminate script execution at this point.  On exit the last reviewed task number is shown.

# DEPENDENCIES

Taskwarrior 2.2.0+ must be installed.

Some needed modules ship with perl (as of 5.06):

- Term::ANSIColor
- Term::ReadLine

But some do not:

- Term::ReadLine::Gnu (Perl extension for the GNU Readline/History Library)

You will need to install it from your distribution (this is libterm-readline-gnu-perl.deb package in debian-like) or get it from CPAN.


# CONFIGURATION

No configuration is necessary if you can go with the hard wired defaults (see FILES for parameter details).  Otherwise the script source code can be edited or a configuration file can be created.

## Source code

Hard wired defaults (mark tag and marking actions, filter, upper and lower labels, localization, info view, time counter, prompt text, label and separator styles) can be modified directly in the Configuration section of the script source code.  As perl is an interpreted scripting language, no compilation or build is needed.  Currently you can choose between two localizations: eng-USA and esp-ESP.

## Configuration file

Default `trev` behavior can be configured, as well as pre-configured *named reviews* can be defined in an optional configuration file named `trevrc` or `.trevrc`.  See FILES for `trevrc` syntax and semantics.

## INSTALL

In order to simplify shell calls to `perl trev.pl` and to avoid shell interpolation of arguments two ways can be followed:

1. Add an alias in your `.bashrc` , `.bash_aliases` or similar:

```
alias trev='perl ~/path/to/the/script/trev.pl'
```

2. Create an executable shell script somewhere in your path (`~/bin/trev`), containing: 

```
#!/bin/sh
perl ~/path/to/the/script/trev.pl $*
```
Use it, in both cases, as:

```
$ trev arguments
```

Allowing or not shell interpolation of arguments may cause different behavior.


# EXAMPLES

`trev` trev can be replaced by `perl ~/path/to/the/script/trev.pl`

- `trev`

    Reviews tasks (user's task default filter), starts reviewing at first of them (default), mark/unmark current task with start/stop (default).

- `trev ++week`

    Sets marking tag to +week and mark/unmark current task with 'modify +week'/'modify -week'.

- `trev ++calendula +ate\_loops`

    Mark/unmark using 'modify +/-calendula'; reviews only ate\_loops tagged tasks.

- `trev ++deleg 113+ pro:wp5`

    Sets marking tag to +deleg, start reviewing at task 113 and process only tasks appertaining to a certain wp5 project.

- `trev 113+ due:`

    Processes only tasks without a due date.  Start at task 113.  Mark/unmark with start/stop and starts at the top of the list (defaults).

- `trev ++NOW overdue`

    Processes overdue tasks.  Mark/unmark with 'modify +/-NOW'.

- `trev 113`

    Reviews just task 113.  Start/stop for mark/unmark (default).

- `trev amsterdam`

    Reviews every task containing amsterdam in its description, starting at the top of the list and marking/unmarking with start/stop.

- `trev -T 'Make these phone calls\\!' -t 'These are high-urgency actionable tasks!' ++call  urgency.over:12 +READY`

    Reviews every task with an urgency.over:12 and marked +READY, starting at the top of the list and marking/unmarking with mod +call/-call.  'Make these phone calls!' and 'These are high-urgency actionable tasks!' appear respectively at the end of upper and lower labels.  Remark the necessary escaping quotation marks.

- `trev wp5`

    Reviews tasks following settings in a single or cascaded named review defined in the configuration file. 


# FILES

## trevrc

`trevrc` (or `.trevrc` depending on the location), is an optional plain text file that can contain configuration instructions for `trev` and is looked for and read at the beginning of every execution.  Instructions in this file are in the form:
```
review.name.parameter = value
```
where 'review' must be always present as is, 'name' names a *named review*, 'parameter' refers to an specific behavioral aspect and 'value' concretes this behavior. So:
```
review.default.L10N       = esp-ESP
```
specifies that the Spanish localization must be used instead of the hard wired default eng-USA.

Any number of blanks or tabs can be used before, after or between the three tokens 'review.name.parameter', '=' and 'value'; but if in 'value' blanks are desired to appear at the beginning or at the end of the string, like in: 
```
review.wp5*.upper        = '           **THIS IS IMPORTANT**'
```
it must be enclosed between quotations.  No shell escaping is needed.

The following paths are searched, in this order, for the configuration file:

- `~/.task/trevrc`
- `~/.trevrc` (note the dot, hidden file).
- `[trev.pl script dir]/trevrc` (mainly for development+repository purposes)

First file found is used.

## Default behavior in trevrc

Default behavior --different from hard wired defaults-- for `trev` can be configured by defining the special named review 'default' in the configuration file. An example default set of parameters follows:
```
# ------------------------------------------------- default behavior/parameters
review.default.seltag     = +hard  +donow
review.default.on         = modify +donow
review.default.off        = modify -donow
review.default.filter     = +hard

review.default.L10N       = esp-ESP
review.default.viewinfo   = off
review.default.showtime   = on

review.default.prompt     = 'trev> '     # quotes to include blank
review.default.upper      = 
review.default.lower      = [modo por defecto: hard=>donow]
review.default.lblstyle   = reverse bold
review.default.sepstyle   = underline bold
```
Blank/void lines as well as anything following a '#' character is ignored.

## Parameter and hard wired defaults

Explanations concerning parameters follow, indicating the hard wired defaults:

- seltag

    (active) Tag (or report) used as mark for selected tasks.

- on

    (start) Taskwarrior command that makes the current task part of the selected set. (More usually this would be something as 'modify +markingtag'.

- off

    (stop) Taskwarrior command that takes out the current task part from the selected set.

- filter

    ('') Expression that Taskwarrior will use as filter to get the task(s) to review. 

- L10N

    (eng-USA) Localization used for program messages.  Values can be {eng-USA , esp-ESP}.

- viewinfo

    (on) This switch (on/off) causes the program to show (or not) detailed information on the task being reviewed.

- showtime

    (on) This switch (on/off) makes the program show time spent in the review at exit.

- prompt

    ('trev> ')

- upper

    ('') Additional text to appear at the upper label.

- lower

    ('') Additional text to appear at the lower label.

- lblstyle

    (reverse bold) Decoration style for labels.  It depends on the capabilities of the console. 

- sepstyle

    (underline bold) Decoration style for the separation between panel (counter, selected, task, labels) and prompt line.  It depends on the capabilities of the console. 


## Named reviews

Parameter values for specific, frequent reviews can be defined in the configuration file and invoked in an easier way from the command line using its *name* as an argument:
```
$ trev calls
```
Definition of a named review is performed by issuing configuration instructions referring to the name in trevrc, e.g.: for the review named calls:
```
# ------------------------------------------------------------- Calls
review.calls.filter      = +phone urgency.over:12 +READY
review.calls.seltag      = +call
review.calls.on          = mod +call
review.calls.off         = mod -call
review.calls.prompt      = 'trev calls> '  # quotes to include blank
review.calls.upper       = Make these phone calls!
review.calls.lower       = These are high-urgency actionable tasks!
```

Those parameter undefined for the review (lblstyle and sepstyle in the example) are taken from defaults, so a named review can be defined with a single line in trevrc:
```
review.tod.filter = due.after:yesterday and due.before:tomorrow status:pending and -rev
```
that takes every other parameter from defaults.


## Cascaded named reviews

Complex review patterns can benefit from a sequential structure as multi-step, multi-level or cascaded sets of reviews, that can be oriented to grouping together, progressively refining, etc.  Named reviews can be used in `trev` in a standalone way or cascaded, i.e.: starting at an specific named review, and when this one is finished the user is asked whether to stop the sequence or to continue with next named review in the sequence, until it finishes.  Sequence can be entered at any single named review, not necessarily at the beginning, and proceeding from there on, so the user can stop and resume later a formerly interrupted (between two steps) review.

Definition of a cascaded review is performed in the configuration file as an *ordered* group of named reviews sharing a common prefix in its name, being this prefix separated from the specific name of the step by a '`*`' character and preceding it.  An example follows for a cascaded review that performs the reviewing of a certain wp5 project in two steps: first tasks with a deadline and then those without one: 
```
# ----------------------------------------------- wp5 multi
review.wp5*.filter       = pro:wp5
review.wp5*.upper        = '                 **IMPORTANT**'

review.wp5*due.filter    = pro:wp5 and due.any:  # deadline
review.wp5*due.lower     = This is wp5-due

review.wp5*notdue.filter = pro:wp5 and due.none: # no deadline
review.wp5*notdue.lower  = This is wp5-notdue
```
The first group, `wp5*`, without any specific step name, is used as a container for parameters common to all steps, but those parameter can be overwritten by definitions in single steps. So, `review.wp5*.filter` is here of any use because every step defines its own, overwriting filter; but `review.wp5*.upper` is used by `wp5*due` and `wp5*notdue` because `upper` is not defined for them.  Every other parameter is taken from defaults.  Order of the groups establishes the step review order: first single named review is addressed first, then second and so on.

Cascaded reviews are invoked with its prefix, followed or not by '`*`':
```
$ trev wp5
```
or
```
$ trev wp5*
```

and starts with `wp5*due`, proceeding till the natural end of it of when the user interrupts the review by means of the usual terminating commands: `q`, `quit`, `exit` or `bye`.  At this point the user is informed and prompted:
```
#
# Multi-step review (wp5):
#
#   Finished step : wp5*due
#   Next step     : wp5*notdue
#

Proceed [RET] or [quit]? > 
```
If `q[uit]` (plus `[RET]`) is issued the whole review is terminated.  If `[RET]` is issued instead the program proceeds with the `wp5*notdue` step till this end or termination, when the user is informed:
```
#
# Multi-step review (wp5):
#
#   Finished step : wp5*notdue (last)
#
```
and the cascaded review is finished.

As previously said, the sequence can be entered at an intermediate review:
```
$ trev wp5*notdue
```

following afterwards the usual course.

## Taskwarrior executable

The script issues system calls to 'task', and this is the expected name of the task executable. This can be modified inside the source code.

# CAVEATS

This is a slow script, specially when --after an action-- the order or number of tasks changes and next task must be located through its uuid.

In principle the script is intended to be used off-line, but if orders can come in any form from the web, beware: system calls are issued through perl backticks and any security check is performed.

# BUGS

https://github.com/nocejo/trev/issues



# AUTHOR

Fidel Mato \<fidel.mato at gmail.com\>.

# COPYRIGHT AND LICENSE

Copyright 2013-2015, Fidel Mato

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

22-May-2015
