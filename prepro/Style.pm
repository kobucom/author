#!/usr/bin/env perl

package Style;

# block-level style handler 
# 20-sep-25 written
# 20-sep-26 tested
# 20-sep-28 startup code added

# Style.pm has two interfaces:
# - call processFile() and all done; syntax is fixed as {class} ... {end}
# - you read input and write output and calls enter() and leave() directly
#   if you see class 'right' call $style->enter('right') to get a tag to output.
#   if you see the end marker calls $style->leave().
#
# Style.pm can handle two types of style names:
# - if the style table is supplied and the style name is defined in the table,
#   a tag in the table is output (or returned).
# - otherwise the name is treated as a class name already defined in the stylesheet.
#   <div class="name">
#     ...
#   </div><!-- name -->

use strict;
use warnings;

use Getopt::Long;

use lib "$ENV{PREPRO_AUTHOR}";
use Parser qw(warn_print);

# debug
use Data::Dumper qw(Dumper);

# constants
use constant { true => 1, false => 0 };

# constructor()
sub new {
    my ($class) = @_;
    return bless {
        stack => [] # array reference to the internal style name stack
        # styles => { optional hash reference to a style table }
    }, $class;
}

# $begin_tag = $self->enter($name);
sub enter {
    my ($self, $name) = @_;
    my $tag = qq(<div class="$name">); # default: output as a class name
    my $styles = $self->{styles}; 
    my $entry = $styles && $styles->{$name} ? $styles->{$name} : undef;
    if (defined($entry)) { # defined in the table
        # check for only_after case
        my $prev = $entry->{only_after};
        if ($prev) {
            if (@{$self->{stack}} == 0 || $self->{stack}->[-1] ne $prev) {
                warn_print("Style::enter: $name not following $prev");
                return "<!-- $name not only_after $prev -->";
            }
            # case satisfied
            pop @{$self->{stack}}; # replace top
        }
        $tag = $entry->{begin_tag} // "<!-- begin $name -->";
    }
    push(@{$self->{stack}}, $name);
    return $tag; 
}

# $end_tag = $self->leave($self);
sub leave {
    my ($self) = @_;
    my $name = pop @{$self->{stack}};
    if ($name) { # has something to end
        my $styles = $self->{styles}; 
        my $entry = $styles && $styles->{$name} ? $styles->{$name} : undef;
        if (defined($entry)) { # defined in the table
            return $entry->{end_tag} // "<!-- end of $name -->";
        }
        else { # ends <div> with the class name
            return "</div><!-- $name -->";
        }
    }
    else { # no matching begin tag
        warn_print("Style::leave: no matching begin tag");
        return "<!-- end of ??? -->";
    }
}

# processFile($input, $output, [\%state])
sub processFile {
    my ($input, $output, $state) = @_;
    my $style = new Style;
    if ($state && $state->{styles}) { $style->{styles} = $state->{styles}; }
    while ( my $line = <$input> ) {
        if ($line =~ /^\{end\}\s*$/) { # {end}
            print $output "\n\n" . $style->leave() . "\n\n";
        }
        elsif ($line =~ /^\{(\w+)\}\s*$/) { # {name}
            my $name = $1;
            print $output "\n\n" . $style->enter($name) . "\n\n";
        }
        else {
            print $output $line;
        }
    }
}

{
    # style table:
    #  begin_tag (mandatory) - starting tag output if enter(name) is seen
    #  end_tag (mandatory) - ending tag output if leave() is called for the name
    #   * begin_tag and end_tag should always be defined but can be ''
    #  only_after (optional) - next name of a chainged style
    #   * when chained, end_tag of the previous style is not output and 
    #     only begin_tag of the following style will be output.
    my $styles = {
        leftcol => {
            begin_tag => q(<div style="float: left">),
            end_tag => q(</div><div style="clear: both"></div>)
        },
        rightcol => {
            begin_tag => q(</div><div style="float: right">),
            end_tag => q(</div><div style="clear: both"></div>),
            only_after => 'leftcol'
        },
        # test
        first => {
            begin_tag => 'Begin First',
            end_tag => 'End First (only seen if this style is used alone)'
        },
        second => {
            begin_tag => 'End First and Begin Second',
            end_tag => 'End Second (never used)',
            only_after => 'first'
        },
        third => {
            begin_tag => 'End Second and Begin Third',
            end_tag => 'End Third',
            only_after => 'second'
        }
    };

    # standalone startup code
    if ($0 =~ /\bStyle.pm$/) {
        # Usage: Style.pm [--debug]
        GetOptions ('debug' => sub { Parser::setDebug(true); });

        my $input = *STDIN;
        my $output = *STDOUT;
        processFile($input, $output, { styles => $styles });
    }
}

true; # need to end with a true value
