#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use DBI;
use CGI;

my $dsn = 'dbi:Pg:dbname=web_app;host=localhost';
my $db_user_name = 'test_user';
my $db_password = 'qwerty';
my ($sql, $sth, $sth2, $ref, $ref2);
my ($user_name, $user_fam, $user_phone, $user_id, $user_status);
my $command;
my $page = 1;

my $q = CGI->new;

my $dbh = DBI->connect($dsn, $db_user_name, $db_password, {AutoCommit => 1, RaiseError => 1, PrintError => 1}) or died("$!\n");

$page = $q->param('page');

print $q->header(-type=>'text/html',-charset=>'UTF-8'),
	$q->start_html;

if (not defined $page or $page eq '1') {
    print $q->start_form(-method=>'POST', -action=>'web_app2.pl');
    print $q->hidden(-name=>'page', -default=>'2');
    print $q->submit(-label=>'Отчёт по периодам (Страница 2)');
    print $q->end_form;

    print "<h1>Пользователи</h1>";

    my $user_name = $q->param('user_name');
    my $user_fam = $q->param('user_fam');
    my $user_phone = $q->param('user_phone');
    my $command = $q->param('command');
    my $user_id = $q->param('user_id');
    my $user_status = $q->param('user_status');

    $q->delete_all();

    if ($command eq 'save_user' and (defined $user_name and $user_name ne '') and (defined $user_fam and $user_fam ne '') and defined $user_phone) {
	$sth = $dbh->prepare('INSERT INTO users(name,fam,phone,status_id,reg_time) VALUES(?,?,?,0,NOW())');
	$sth->execute($user_name,$user_fam,$user_phone);
    } elsif ($command eq "save_status" and (defined $user_status and $user_status ne '') and (defined $user_id and $user_id ne '')) {
	$sth = $dbh->prepare('UPDATE users SET status_id=? WHERE id=?');
	$sth->execute($user_status,$user_id);
	$user_status = undef;
    }
    
    $sth = $dbh->prepare('SELECT users.id, name, fam, phone, status_id, date(reg_time) FROM users LEFT JOIN user_status ON users.status_id = user_status.id ORDER BY users.id');
    #$sth = $dbh->prepare('SELECT users.id, name, fam, phone, status_id, date(reg_time) FROM users ORDER BY users.id');
    $sth->execute();

    $sth2 = $dbh->prepare('SELECT * FROM user_status');
    $sth2->execute();
    $ref2 = $sth2->fetchall_arrayref();
    $dbh->disconnect();
    died "Ошибка: таблица User_status пуста" unless (@$ref2);
    my (%status);
    map {$status{$_->[0]}=$_->[1]} @$ref2;

    $ref = $sth->fetchall_arrayref();

    print $q->start_form(-method=>'POST');
    print "<table>";
    print "<tr><td>Имя</td><td>Фамилия</td><td>Телефон</td><td></td></tr>";
    print "<tr><td>";
    print $q->textfield(-name=>'user_name', -size=>50, -maxlength=>50);
    print "</td><td>";
    print $q->textfield(-name=>'user_fam', -size=>50, -maxlength=>50);
    print "</td><td>";
    print $q->textfield(-name=>'user_phone', -size=>10, -maxlength=>10);
    print "</td><td>";
    print $q->submit(-label=>'Добавить');
    print "</td></tr>";
    print "</table>";
    print $q->hidden(-name=>'command', -default=>'save_user');
    print $q->end_form;

    if (@$ref) {    
	print "<table>";
        print "<tr><td>Имя</td><td>Фамилия</td><td>Телефон</td><td>Статус</td><td>Дата регистрации</td></tr>";
	foreach(@$ref) {
	    print "<tr><td>$_->[1]</td><td>$_->[2]</td><td>$_->[3]</td><td>";
    	    print $q->start_form(-method=>'POST');
    	    print $q->popup_menu(-name=>'user_status', -values=>\%status, -default=>$_->[4]);
	    print $q->hidden(-name=>'user_id', -default=>$_->[0]);
	    print $q->hidden(-name=>'command', -default=>'save_status');
	    print $q->submit(-label=>'Сохранить');
	    print $q->end_form;
	    print "</td><td>$_->[5]</td></tr>";
	}
	print "</table>";    
    } else {
	print "Таблица Users пуста";
    }

}

print $q->end_html;

sub died
{
    my $text = shift;
    print $q->h3("$text\n");
#    die;
}