package Net::Server::Mail::ESMTP::PIPELINING;

use 5.006;
use strict;
use constant GROUP_COMMANDS => [qw(RSET MAIL SEND SOML SAML RCPT)];

sub new
{
    my($proto, $parent) = @_;
    my $class  = ref $proto || $proto;
    my $self   = {};
    bless($self, $class);
    $parent->{process_operation} = \&process_operation;
    return $self;
}

sub process_operation
{
    my($self, $operation) = @_;
    warn $operation."[end]";
    my @commands = grep(length $_, split(/\r?\n/, $operation));
    for(my $i = 0; $i <= $#commands; $i++)
    {
        next unless length;
        my($verb, $params) = $self->tokenize_command($commands[$i]);

        # Once the client SMTP has confirmed that support exists for
        # the pipelining extension, the client SMTP may then elect to
        # transmit groups of SMTP commands in batches without waiting
        # for a response to each individual command. In particular,
        # the commands RSET, MAIL FROM, SEND FROM, SOML FROM, SAML
        # FROM, and RCPT TO can all appear anywhere in a pipelined
        # command group.  The EHLO, DATA, VRFY, EXPN, TURN, QUIT, and
        # NOOP commands can only appear as the last command in a group
        # since their success or failure produces a change of state
        # which the client SMTP must accommodate. (NOOP is included in
        # this group so it can be used as a synchronization point.)
        if($i < $#commands && not grep($verb eq $_, @{(GROUP_COMMANDS)}))
        {
            $self->reply(550, "Protocol error: `$verb' not allowed in a group of commands");
            return;
        }

        my $rv = $self->process_command($verb, $params);
        return $rv if defined $rv;
    }
    return
}

sub verb
{
    return ();
}

sub keyword
{
    return 'PIPELINING';
}

sub parameter
{
    return ();
}

sub option
{
    return ();
}

sub reply
{
    return ();
}

1;
