# OpenXPKI::Client::UI::Result
# Written 2013 by Oliver Welter
# (C) Copyright 2013 by The OpenXPKI Project

package OpenXPKI::Client::UI::Result;

use OpenXPKI::i18n qw( i18nGettext );
use OpenXPKI::Serialization::Simple;

use Moose; 

has cgi => (       
    is => 'ro',
    isa => 'Object',
);

has extra => (       
    is => 'rw',
    isa => 'HashRef',
    default => sub { return {}; }    
);

has _client => (       
    is => 'ro',
    isa => 'Object',
    init_arg => 'client'
);

has _error => (       
    is => 'rw',
    isa => 'HashRef|Undef',
);

has _page => (
    is => 'rw',      
    isa => 'HashRef|Undef',
    lazy => 1,
    default => undef        
);

has _status => (    
    is => 'rw',   
    isa => 'HashRef|Undef',
);

has _result => (
    is => 'rw',       
    isa => 'HashRef|Undef',
    default => sub { return {}; }
);

has reload => (
    is => 'rw',       
    isa => 'Bool',
    default => 0,
);

has redirect => (
    is => 'rw',       
    isa => 'Str',
    default => '',
);

has serializer => (
    is => 'ro',       
    isa => 'Object',
    lazy => 1,
    default => sub { return OpenXPKI::Serialization::Simple->new(); }  
);

sub BUILD {
    
    my $self = shift;
    # load global client status if set 
    if ($self->_client()->_status()) {
        $self->_status(  $self->_client()->_status() );
    }
    
}
sub add_section {
    
    my $self = shift;
    my $arg = shift;
    
    push @{$self->_result()->{main}}, $arg;
    
    return $self;
    
}

sub set_status {
    
    my $self = shift;
    my $message = shift;
    my $level = shift || 'info';
    
    $self->_status({ level => $level, message => $message });
    
    return $self;
    
}


sub send_command {
    
    my $self = shift;
    my $command = shift;
    my $params = shift || {};
    
    my $backend = $self->_client()->backend();
    my $reply = $backend->send_receive_service_msg( 
        'COMMAND', { COMMAND => $command, PARAMS => $params }  
    );
    
    if ( $reply->{SERVICE_MSG} ne 'COMMAND' ) {
        $self->logger()->error("command $command failed ($reply->{SERVICE_MSG})");
        $self->set_status_from_error_reply( $reply );
        return undef;
    }
    
    return $reply->{PARAMS};
    
} 

sub set_status_from_error_reply {
    
    my $self = shift;
    my $reply = shift;
    
    my $message = 'I18N_OPENXPKI_UI_UNKNOWN_ERROR'; 
    if ($reply->{'LIST'} 
        && ref $reply->{'LIST'} eq 'ARRAY') {            
        # Workflow errors            
        if ($reply->{'LIST'}->[0]->{PARAMS} && $reply->{'LIST'}->[0]->{PARAMS}->{__ERROR__}) {
            $message = $reply->{'LIST'}->[0]->{PARAMS}->{__ERROR__};
        } elsif($reply->{'LIST'}->[0]->{LABEL}) {    
            $message = $reply->{'LIST'}->[0]->{LABEL};
        }            
        $self->logger()->error($message);        
    }   
    $self->_status({ level => 'error', message => i18nGettext($message) });
    
    return $self;
}

sub param {
    
    my $self = shift;
    my $key = shift;
    
    my $extra = $self->extra()->{$key};
    return $extra if (defined $extra);
                
    my $cgi = $self->cgi();
    return undef unless($cgi);
    
    if (wantarray) {
        return \({$cgi->param($key)});
    }   
    return $cgi->param($key);
}

sub logger {
    
    my $self = shift;
    return $self->_client()->logger();
}

sub render {
    
    my $self = shift;
    
    my $result = $self->_result();

    $result->{error} = $self->_error() if $self->_error();
    $result->{status} = $self->_status() if $self->_status();    
    $result->{page} = $self->_page() if $self->_page();
    $result->{reloadTree} = 1 if $self->reload();
    $result->{goto} = $self->redirect() if $self->redirect();
    
    return $result;
}

1;