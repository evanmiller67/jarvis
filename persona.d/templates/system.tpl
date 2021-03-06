---
persona:   
  class: Jarvis::Persona::System
  init: 
    alias: system
    trace: 1
    peer_group: cn=bot_managed
    ldap_domain: [% DOMAIN %]
    ldap_bindpw: [% SECRET %]
  connectors:
    - class: Jarvis::IRC
      init:
        alias: [% HOSTNAME %]_irc
        nickname: [% HOSTNAME %]
        ircname: [% FQDN %]
        server: [% IRC_SERVER %]
        domain: [% DOMAIN %]
        channel_list:
          - #asgard
        persona: system
    - class: Jarvis::Jabber
      init: 
        alias: [% HOSTNAME %]_xmpp
        ip: [% FQDN %]
        port: 5222
        hostname: [% DOMAIN %]
        username: [% HOSTNAME %]
        password: [% XMPP_PASSWORD %]
        channel_list: 
          - asgard\@conference.[% DOMAIN %]/[% HOSTNAME %]
        persona: system

