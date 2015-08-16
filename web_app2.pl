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

my $q = CGI->new;

my $dbh = DBI->connect($dsn, $db_user_name, $db_password, {AutoCommit => 1, RaiseError => 1, PrintError => 1}) or died("$!\n");

my $days = $q->param('days');

print $q->header(-type=>'text/html',-charset=>'UTF-8'),
	$q->start_html;

    print $q->start_form(-method=>'POST', action=>'web_app.pl');
    print $q->submit(-label=>'Пользователи (Страница 1)');
    print $q->end_form;

    $q->delete_all();

    print "<h1>Конверсия по периодам</h1>";

    print $q->start_form(-method=>'POST', action=>'web_app2.pl');
    print "Дней в периоде: ";
    print $q->textfield(-name=>'days', -size=>5, -maxlength=>5, -default=>$days);
    print $q->submit(-label=>'Установить');
    print $q->end_form;

    if (not defined $days) {
	$days = 1;
	show_conv();
    } else {
	if (not $days =~ /^\d+$/) {
	    print "Неверное значение дней: \'$days\', должно быть целое неотрицательное число"
	} elsif ($days =~ /^0+$/) {
	    print "Неверное значение дней: \'$days\', количество не может быть 0"
	} else {
	    show_conv();
	}
    }

print $q->end_html;

sub died
{
    my $text = shift;
    print $q->h3("$text\n");
}

sub show_conv
{
	    my $strdays = "$days days";
	    $sth = $dbh->prepare(qq{WITH RECURSIVE dtimes(mt, nt) AS (
					SELECT
					    min(reg_time) mt,
					    min(reg_time) + INTERVAL '$strdays' nt
					FROM users
					    UNION ALL
					SELECT
					    t.nt mt,
					    t.nt + INTERVAL '$strdays' nt
					FROM dtimes t
					WHERE nt <= (SELECT max(reg_time) FROM users))
					    SELECT
						to_char(date_trunc('day', mt), 'YYYY-MM-DD'),
						to_char(date_trunc('day', nt), 'YYYY-MM-DD'),
						(SELECT (caid * 100 / (SELECT count(*) FROM USERS))
						FROM (SELECT
							count(a.id) caid
							FROM (SELECT
								id
								FROM users
								WHERE status_id=1 and reg_time >= mt and reg_time < nt
							    ) a
						    ) b
						) || '%' conv
					    FROM dtimes
					    ORDER BY dtimes.mt
				    });
	    $sth->execute();
	    $ref = $sth->fetchall_arrayref();

	    if (@$ref) {
		print "<table>";
		print "<tr><td>Начало периода</td><td>Окончание периода</td><td>Конверсия за период</td></tr>";
		foreach (@$ref) {
		    print "<tr><td>$_->[0]</td><td>$_->[1]</td><td>$_->[2]</td></tr>";
		}
		print "</table>";
	    } else {
		died("Таблица users пуста");
	    }
}