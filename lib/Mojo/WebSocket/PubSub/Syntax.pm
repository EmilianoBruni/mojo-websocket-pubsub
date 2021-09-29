package Mojo::WebSocket::PubSub::Syntax;

use Mojo::Base 'Mojo::EventEmitter';
use Time::HiRes qw(gettimeofday);

has 'lang_lookup' => \&_lang_lookup;

sub keepalive {
    return { t => 'k' };
}

sub ping() {
    return { t => 'ping', cts => [gettimeofday] };
}

sub pong {
    my $s = shift;
    my $ping = shift || return;
    $ping->{t} = 'pong';
    $ping->{sts} = [gettimeofday];
    return $ping;
}

sub join {
    my $s = shift;
    my $ch = shift;
    return {t => 'join', ch => $ch};
}

sub joined {
    my $s = shift;
    my $join = shift || return;
    $join->{t} = 'joined';
    return $join;
}

sub mc2s {
    my $s = shift;
    my $msg = shift || return;
    return {t => 'mc2s', msg => $msg};
}

sub ms2b {
    my $s = shift;
    my $msg = shift || return;
    my $from = shift || return;
    $msg->{t} = 'ms2b';
    $msg->{from} = $from;

    return $msg;
}

sub parse {
    my $s   = shift;
    my $msg = shift || return;

    my $cmd = $msg->{t};
    return unless exists $s->lang_lookup->{$cmd};
    my $ll = $s->lang_lookup->{$cmd};

    $s->emit( all          => $ll->{cb}->( $s, $msg ) );
    $s->emit( $ll->{event} => $ll->{cb}->( $s, $msg ) );
}

sub _lang_lookup {
    my $s  = shift;
    my $ll = {
        k => {
            event => 'keepalive',
        },
        ping => {
            event => 'ping'
        },
        pong => {
            event => 'pong'
        },
        join => {
            event => 'join'
        },
        joined => {
            event => 'joined'
        },
        mc2s => {
            event => 'mc2s'
        },
        ms2b => {
            event => 'ms2b'
        },
    };
    foreach ( keys %$ll ) {
        $ll->{$_}->{cb} = \&{ __PACKAGE__ . "::_exec_$_" };
    }
    return $ll;
}

sub _exec_k { }

sub _exec_ping {
    return $_[1];
}

sub _exec_pong {
    return $_[1];
}

sub _exec_join {
    return $_[1];
}

sub _exec_joined {
    return $_[1];
}

sub _exec_mc2s {
    return $_[1];
}

sub _exec_ms2b {
    return $_[1];
}

1;
__END__

# ABSTRACT: Syntax parser/builder for communication in Mojo::WebSocket::PubSub

=pod

=encoding UTF-8

=begin :badge

=begin html

<p>
    <a href="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/mojo-websocket-pubsub/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/mojo-websocket-pubsub">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/mojo-websocket-pubsub">
</p>

=end html

=end :badge

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::WebSocket::PubSub::Syntax

=cut
