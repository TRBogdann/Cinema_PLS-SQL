--1
CREATE OR REPLACE PROCEDURE LOCURI_LIBERE(id_viz in p_program.id_vizionare%type)
IS
v_rand p_sali_cinema.nr_randuri%type;
v_capacitate p_sali_cinema.capacitate_rand%type;
v_nr int :=0;
v_ex int :=0;
exc_loc exception;
BEGIN

SELECT s.nr_randuri,s.capacitate_rand
INTO v_rand,v_capacitate
FROM p_program p
JOIN p_sali_cinema s
ON s.id_sala = p.id_sala
WHERE p.id_vizionare = id_viz;

FOR i in 0..v_rand
LOOP
FOR j in 0..v_capacitate
LOOP
SELECT count(b.id_bilet)
INTO v_ex
FROM p_bilet b
JOIN p_program p
ON b.id_vizionare = p.id_vizionare
WHERE b.nr_loc = j and b.nr_rand = i;
IF v_ex = 1 THEN
v_nr := v_nr + 1;
DBMS_OUTPUT.PUT_LINE('RAND: '||to_char(i)||' LOC: '||to_char(j));
END IF;
END LOOP;
END LOOP;

IF v_nr = 0 THEN
RAISE exc_loc;
END IF;

DBMS_OUTPUT.PUT_LINE('Au fost gasite '||to_char(v_nr)||' locuri libere');

EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('Nu a fost gasit spectacolul');
WHEN exc_loc THEN
DBMS_OUTPUT.PUT_LINE('Nu au fost gasite locuri libere');
END;
/

CREATE OR REPLACE PROCEDURE STERGERE_PREV
IS
v_id p_program.id_vizionare%type;
v_count int := 0;
cursor v_cursor
IS
SELECT id_vizionare
FROM p_program
WHERE data_vizionare < SYSDATE;
exc_del exception;
BEGIN

open v_cursor;
LOOP
FETCH v_cursor INTO v_id;
EXIT WHEN v_cursor%NOTFOUND;
DELETE FROM p_bilet
WHERE id_vizionare = v_id;
DELETE FROM p_program
WHERE id_vizionare = v_id;
v_count := v_count + 1;
END LOOP;

IF v_count = 0 THEN
RAISE exc_del;
END IF;

DBMS_OUTPUT.PUT_LINE('Au fost sterse ' || to_char(v_count) || ' inregistrari');

EXCEPTION
WHEN exc_del THEN
DBMS_OUTPUT.PUT_LINE('Spectacolele anterioare au fost deja sterse');
END STERGERE_PREV;
/



CREATE OR REPLACE PROCEDURE STATISTICI_FILME
IS
v_id p_filme.id_film%type;
v_nume p_filme.nume_film%type;
v_bilete int := 0;
v_suma int := 0;
v_total int := 0;
cursor cursor_film
IS
SELECT id_film,nume_film
FROM p_filme;
BEGIN
open cursor_film;
LOOP
FETCH cursor_film into v_id,v_nume;
EXIT WHEN cursor_film%NOTFOUND;
BEGIN
DBMS_OUTPUT.PUT_LINE(to_char(v_id));
SELECT f.nume_film,count(b.id_bilet),nvl(sum(b.pret),0)
INTO v_nume,v_bilete,v_suma
FROM p_filme f
JOIN p_program p
ON p.id_film = f.id_film
JOIN p_bilet b
ON p.id_vizionare = b.id_vizionare
WHERE f.id_film = v_id
GROUP BY f.nume_film;

DBMS_OUTPUT.PUT_LINE(v_nume||':');
IF v_bilete = 0 AND v_suma = 0 THEN
DBMS_OUTPUT.PUT_LINE('Spectacolul nu a vandut bilete');
ELSE
DBMS_OUTPUT.PUT_LINE('Bilete Vandute: ' || to_char(v_bilete) || ' Suma incasata: ' || to_char(v_suma));
v_total := v_total + v_suma;
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE(v_nume||':');
DBMS_OUTPUT.PUT_LINE('Spectacolul nu a vandut bilete');
END;
END LOOP;
DBMS_OUTPUT.PUT_LINE('Total Incasat: ' || to_char(v_total));
END STATISTICI_FILME;
/

--4
CREATE OR REPLACE PROCEDURE MAJORARE_SALARIU_FUNCTIE(id_func in p_angajati.functie%type, procent in NUMBER)
IS
cursor cursor_ang(id_f p_angajati.functie%type)
IS
SELECT id_angajat
FROM p_angajati
WHERE functie = id_f;
exc_noang exception;
v_found int := 0;
v_rows int := 0;
v_id p_angajati.id_angajat%type;
BEGIN
OPEN cursor_ang(id_func);
LOOP
FETCH cursor_ang INTO v_id;
EXIT WHEN cursor_ang%NOTFOUND;
v_rows := v_rows + 1;
UPDATE p_angajati
SET salariul = salariul + salariul * procent
WHERE functie = id_func;
END LOOP;

IF v_rows = 0 then
RAISE exc_noang;
END IF;
dbms_output.put_line('Salariul a fost modificat pentru ' || to_char(v_rows) || ' angajati');
EXCEPTION
WHEN exc_noang THEN
dbms_output.put_line('Nu au fost gasiti angajati cu functia selectata');

END MAJORARE_SALARIU_FUNCTIE;
/

--5
CREATE OR REPLACE PROCEDURE UPCOMING
IS
v_nume p_filme.nume_film%type;
v_data p_filme.data_lansare%type;
cursor c IS
SELECT nume_film,data_lansare
FROM p_filme
WHERE data_lansare > SYSDATE;
v_count int := 0;
BEGIN
open c;
LOOP
FETCH c INTO v_nume,v_data;
EXIT WHEN c%NOTFOUND;
v_count := v_count + 1;
DBMS_OUTPUT.PUT_LINE('Nume: '||v_nume||' Data Lansare: '||to_char(v_data));
END LOOP;

IF v_count = 0 THEN
DBMS_OUTPUT.PUT_LINE('Nu exista filme nelansate');
END IF;
END UPCOMING;
/

--1
SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE ANULARE_REZERVARE(v_id in p_clienti.id_client%type, v_data in p_program.data_vizionare%type)
IS
cursor cursor_bilet IS
SELECT id_bilet 
FROM p_bilet
WHERE id_client = v_id AND id_vizionare = (SELECT id_vizionare FROM p_program WHERE data_vizionare = v_data); 
no_deleted exception;
v_nr int := 0;
v_sel p_bilet.id_bilet%type;
BEGIN
OPEN cursor_bilet;
LOOP
FETCH cursor_bilet into v_sel;
DELETE FROM p_bilet
WHERE id_bilet = v_sel;
EXIT WHEN cursor_bilet%NOTFOUND;
v_nr := v_nr + 1;
END LOOP;

IF v_nr = 0 THEN
RAISE no_deleted;
END IF;

DBMS_OUTPUT.PUT_LINE('Rezervarea a fost stearsa');

EXCEPTION
WHEN  no_deleted THEN
DBMS_OUTPUT.PUT_LINE('Rezervarea nu a fost gasita');
WHEN too_many_rows THEN
DBMS_OUTPUT.PUT_LINE('Clientul a rezervat bilete pentru mai multe spectacole in aceiasi data');

END ANULARE_REZERVARE;
/



--2
SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE VANZARI_CATEGORIE
IS
v_id p_categorii.id_categorie%type;
v_nume p_categorii.nume_categorie%type;
cursor c_cat IS
SELECT id_categorie,nume_categorie
FROM p_categorii;
BEGIN
OPEN c_cat;
LOOP
FETCH c_cat into v_id,v_nume;
EXIT WHEN c_cat%NOTFOUND;
DBMS_OUTPUT.PUT_LINE('Nume Categorie: ' || v_nume);
DECLARE 
v_sum int;
is_null exception;
BEGIN
SELECT sum(b.pret)
INTO v_sum
FROM p_bilet b
JOIN p_program p
ON p.id_vizionare = b.id_vizionare
JOIN p_filme f
ON f.id_film = p.id_film
JOIN p_categorii_film cf
ON cf.id_film = f.id_film
WHERE cf.id_categorie = v_id;

IF v_sum IS NULL then
RAISE is_null;
END IF;

DBMS_OUTPUT.PUT_LINE('Suma Incasata: '||to_char(v_sum));

EXCEPTION
WHEN is_null THEN
DBMS_OUTPUT.PUT_LINE('Categorie nu a generat profit');
END;
END LOOP;
END VANZARI_CATEGORIE;
/



--3 (Folosita in procedura 4)


CREATE OR REPLACE FUNCTION DATA_FILM(v_id p_filme.id_film%type)
RETURN NUMBER
IS
v_data p_program.data_vizionare%type;
it int :=0;
v_nr NUMBER :=0;
cursor c IS
SELECT data_vizionare 
FROM p_program
WHERE id_film = v_id;
BEGIN 
OPEN c;
LOOP
FETCH c INTO v_data;
EXIT WHEN c%NOTFOUND;
v_nr := v_nr + 1;
DBMS_OUTPUT.PUT_LINE(to_char(v_nr) || '.' || to_char(v_data));
END LOOP;
RETURN v_nr;
END DATA_FILM;
/


--4 (AFISARE_LOCURI face parte din partea 1)
SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE REZERVA_LOCURI
IS
TYPE loc IS RECORD(
rand p_bilet.nr_rand%type,
numar p_bilet.nr_loc%type
);
TYPE t IS TABLE OF loc INDEX BY PLS_INTEGER;
v_loc_alese t;
v_nume p_filme.nume_film%type;
v_id p_filme.id_film%type;
v_check int := 0;
v_dat int;
no_date exception;
se_date exception;
v_numar int;
v_viz p_program.id_vizionare%type;
BEGIN
DBMS_OUTPUT.PUT_LINE('Alege Filmul:');
v_nume := '&Film';
SELECT id_film 
INTO v_id
FROM p_filme f
WHERE nume_film = v_nume;

v_check := DATA_FILM(v_id);

IF v_check = 0 THEN 
RAISE no_date;
END IF;

DBMS_OUTPUT.PUT_LINE('Alege data:');
v_numar := &numar;

IF v_numar > v_check THEN
RAISE se_date;
END IF;

DECLARE
cursor c IS
SELECT id_vizionare
FROM p_program
WHERE id_film = v_id;
BEGIN
OPEN c;
FOR i in 1..v_numar
LOOP
FETCH C INTO v_viz;
END LOOP;
CLOSE c;
END;

LOCURI_LIBERE(v_viz);

DBMS_OUTPUT.PUT_LINE('Alege nr de locuri');
v_numar := &locuri;

EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('Filmul nu a fost gasit');
WHEN no_date THEN
DBMS_OUTPUT.PUT_LINE('Filmul nu se mai difuzeaza');
WHEN se_date THEN
DBMS_OUTPUT.PUT_LINE('Data selectata nu exista');
END REZERVA_LOCURI;
/

1.
CREATE OR REPLACE PROCEDURE AFISARE_SUBORDONATI(v_id p_angajati.id_angajat%type)
IS
no_ang exception;
cursor ang_cursor
IS
SELECT id_angajat,nume,prenume
FROM p_angajati
WHERE id_manager = v_id;
type ang IS RECORD(
id_ang p_angajati.id_angajat%type,
nume p_angajati.nume%type,
prenume p_angajati.prenume%type
);
TYPE t is TABLE OF ang INDEX BY PLS_INTEGER;
tabela t;
BEGIN
OPEN ang_cursor;
FETCH ang_cursor BULK COLLECT INTO tabela;

IF tabela.first IS NULL OR tabela.last IS NULL THEN
RAISE no_ang;
END IF;

FOR i in tabela.first..tabela.last
LOOP
DBMS_OUTPUT.PUT_LINE('Id: ' || to_char(tabela(i).id_ang)||' Nume: ' || tabela(i).nume || ' ' || tabela(i).prenume);
END LOOP;

EXCEPTION
WHEN no_ang THEN
DBMS_OUTPUT.PUT_LINE('Angajatul nu exista sau nu are subordonati');
END;
/


2.

CREATE OR REPLACE FUNCTION ORA_SFARSIT(v_id p_program.id_vizionare%type)
RETURN timestamp
IS 
v_inceput timestamp;
v_film p_filme.id_film%type;
v_minute NUMBER;
BEGIN

SELECT data_vizionare,id_film
into v_inceput,v_film
FROM p_program
where id_vizionare = v_id;

SELECT durata_minute
INTO v_minute
FROM p_filme
WHERE id_film = v_film;

RETURN v_inceput + v_minute/(24*60);
END;
/

3.
CREATE OR REPLACE PROCEDURE PLASARE_PROGRAM(v_id p_filme.id_film%type ,v_tip p_program.tip_vizionare%type,v_sala p_program.id_sala%type,deschidere timestamp,inchidere timestamp)
IS
new_id p_program.id_vizionare%type;
type prog is RECORD(
inceput timestamp,
sfarsit timestamp
);
type t is table of prog index by pls_integer;
ore t;
data_final timestamp;
v_durata number;
liber exception; 
terminat exception;
BEGIN

SELECT durata_minute
INTO v_durata
FROM p_filme
WHERE id_film = v_id;

SELECT max(id_vizionare)+1
INTO new_id
FROM p_program;

SELECT data_vizionare,ORA_SFARSIT(id_vizionare)
BULK COLLECT INTO ore
FROM p_program
WHERE data_vizionare > deschidere and data_vizionare < inchidere AND id_sala = v_sala
ORDER by data_vizionare asc;

IF ore.first IS NULL and ore.last IS NULL THEN
DBMS_OUTPUT.PUT_LINE('Filmul a fost plasat la '||to_char(deschidere));
raise liber;
END IF;

IF ore(1).inceput >= deschidere + v_durata/(24*60) then
raise liber;
END IF;

FOR i in ore.first..ore.last-1 
LOOP
IF ore(i).sfarsit + v_durata/(24*60) <= ore(i+1).inceput THEN
INSERT INTO p_program
VALUES(new_id,ore(i).sfarsit,v_tip,v_id,v_sala);
DBMS_OUTPUT.PUT_LINE('Filmul a fost plasat la '||to_char(ore(i).sfarsit));
raise terminat;
end if;
END LOOP;

IF ore(ore.last).sfarsit + v_durata/(24*60) <= inchidere  then
data_final := ore(ore.last).sfarsit;
INSERT INTO p_program
VALUES(new_id,data_final,v_tip,v_id,v_sala);
DBMS_OUTPUT.PUT_LINE('Filmul a fost plasat la '||to_char(data_final));
raise terminat;
END IF;

DBMS_OUTPUT.PUT_LINE('Filmul nu poate plasat in intervalul selectat. Va rugram sa incercati alt interval');

EXCEPTION
WHEN liber then
INSERT INTO p_program
VALUES(new_id,deschidere,v_tip,v_id,v_sala);

WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('Filmul nu exista');
WHEN terminat THEN
DBMS_OUTPUT.PUT_LINE('Procedura a fost icheiata');
END;
/
4+5.

CREATE OR REPLACE FUNCTION VENIT_CATEGORIE_VARSTA(v_cat p_filme.categorie_varsta%type)
return NUMBER
IS
v_sum number;
BEGIN
SELECT sum(b.pret)
INTO v_sum
FROM p_bilet b
JOIN p_program p
ON p.id_vizionare = b.id_vizionare
JOIN p_filme f
ON p.id_film = f.id_film
WHERE f.categorie_varsta = v_cat;

RETURN v_sum;
END;
/

CREATE OR REPLACE PROCEDURE TOP_CATEGORII_VARSTA
IS 
type cat is record(
varsta int,
venit number);
type t is table of cat index by pls_integer;
vector t;
no_cat exception;
BEGIN
SELECT distinct categorie_varsta,NVL(VENIT_CATEGORIE_VARSTA(categorie_varsta),0)
BULK COLLECT INTO vector
FROM p_filme
order by NVL(VENIT_CATEGORIE_VARSTA(categorie_varsta),0) desc;

if vector.first is null and vector.last is null then
raise no_cat;
end if;

FOR i in vector.first..vector.last
LOOP
DBMS_OUTPUT.PUT_LINE('Categorie Varsta: ' || to_char(vector(i).varsta) || ' Venit: ' || to_char(vector(i).venit));
END LOOP;

EXCEPTION
WHEN no_cat then
DBMS_OUTPUT.PUT_LINE('Nu exista categorii de varsta');
END;
/


6.
CREATE OR REPLACE FUNCTION NR_BILETE(v_id p_filme.id_film%type)
RETURN int
IS
v_count int := 0;
temp int;
cursor prog_cursor
IS 
SELECT id_vizionare
FROM p_program
WHERE id_film = v_id;
v_prog p_program.id_vizionare%type;
BEGIN
open prog_cursor;
LOOP
FETCH prog_cursor INTO v_prog;
EXIT WHEN prog_cursor%notfound;
SELECT count(b.id_bilet)
INTO temp
FROM p_bilet b
JOIN p_program p
ON p.id_vizionare = v_prog;
v_count := v_count + temp;
END LOOP;

RETURN v_count;
END;
/

CREATE OR REPLACE TRIGGER trg_locuri
BEFORE INSERT ON P_BILET
FOR EACH ROW
DECLARE 
v_nr int :=0;
v_nr_locuri int :=0;
v_rand int :=0;
v_cap int :=0;
BEGIN
SELECT s.nr_randuri*s.capacitate_rand,s.nr_randuri,s.capacitate_rand
INTO v_nr_locuri,v_rand,v_cap
FROM p_program p
JOIN p_sali_cinema s
ON p.id_sala = s.id_sala
WHERE p.id_vizionare = :new.id_vizionare;

SELECT COUNT(b.id_bilet)
INTO v_nr
FROM p_bilet b
JOIN p_program p
ON b.id_vizionare = p.id_vizionare
WHERE b.id_vizionare = :new.id_vizionare;

IF v_nr >= v_nr_locuri THEN
RAISE_APPLICATION_ERROR(-20020,'Nu exista locuri disponibile');
END IF;

IF :new.nr_rand>v_rand OR :new.nr_loc>v_cap THEN
RAISE_APPLICATION_ERROR(-20021,'Nu exista locul selectat');
END IF;

SELECT count(id_bilet)
INTO v_cap
FROM p_bilet
WHERE nr_rand = :new.nr_rand and nr_loc = :new.nr_loc;

IF v_cap > 0 THEN
RAISE_APPLICATION_ERROR(-20022,'Locul este deja ocupat');
END IF;

END;
/


--2
CREATE OR REPLACE TRIGGER trg_creare_vizionare
BEFORE INSERT ON p_program
FOR EACH ROW
DECLARE
v_final timestamp;
v_durata number;
v_count int := 0;
BEGIN

SELECT durata_minute
INTO v_durata
FROM p_filme 
WHERE id_film = :new.id_film;

v_final := :new.data_vizionare + v_durata/(24*60);

SELECT count(p.id_vizionare)
INTO v_count
FROM p_program p
JOIN p_filme f
ON p.id_film = f.id_film
WHERE (p.data_vizionare <= v_final AND p.data_vizionare >= :new.data_vizionare) OR (p.data_vizionare+f.durata_minute/(24*60) <= v_final AND p.data_vizionare+f.durata_minute/(24*60) >= :new.data_vizionare) AND p.id_sala = :new.id_sala;

IF v_count > 0 THEN
RAISE_APPLICATION_ERROR(-20023,'Sala nu este libera in intervalul ales');
END IF;

END;
/


--3
DROP VIEW view_p_filme;
CREATE VIEW view_p_filme AS
SELECT id_film,nume_film
FROM p_filme;

CREATE OR REPLACE TRIGGER trg_sterge_programv_cascada
INSTEAD OF DELETE ON view_p_filme
FOR EACH ROW

DECLARE
cursor c IS
SELECT id_vizionare
FROM p_program
WHERE id_film = :new.id_film;

v_id p_program.id_vizionare%type;
BEGIN

OPEN c;
LOOP
FETCH c into v_id;
EXIT WHEN c%notfound;

DELETE FROM p_categorii_film
WHERE id_film = :new.id_film;

DELETE FROM p_bilet
WHERE id_vizionare = v_id;

DELETE FROM p_program
WHERE id_vizionare = v_id;
END LOOP;

DELETE FROM p_filme
WHERE id_film = :new.id_film;

END;
/




--4
DROP TABLE p_recenzii;

CREATE TABLE p_recenzii
(
id_client int REFERENCES p_clienti(id_client),
numar_stele int,
id_film int REFERENCES p_filme(id_film),
CONSTRAINT pk_numar CHECK(numar_stele<6 and numar_stele>0)
);

CREATE OR REPLACE PACKAGE pak_filme
IS
PROCEDURE TOP_RECENZII;
PROCEDURE CLIENTI_NR_RECENZII;
PROCEDURE FILME_CAT(v_id p_categorii.id_categorie%type);
END;
/

CREATE OR REPLACE PACKAGE BODY pak_filme
IS

PROCEDURE TOP_RECENZII
IS
type rfilm IS RECORD
(
nume_film p_filme.nume_film%type,
rating number
);
type vec IS TABLE OF rfilm INDEX BY PLS_INTEGER;
arr vec;
cursor c IS
SELECT f.nume_film,
CASE
WHEN count(r.id_client) = 0 THEN 0
ELSE nvl(sum(r.numar_stele),0)/count(r.id_client)
END 
FROM p_filme f
JOIN p_recenzii r
ON f.id_film = r.id_film
GROUP BY f.id_film,f.nume_film
ORDER BY nvl(sum(r.numar_stele),0)/(count(r.id_client)+1) desc;
ex_c exception;
BEGIN
OPEN c;
FETCH c BULK COLLECT INTO arr;
IF arr.first IS NULL THEN
RAISE ex_c;
END IF;
FOR i in arr.first..arr.last
LOOP
DBMS_OUTPUT.PUT_LINE('Nume Film: '||arr(i).nume_film||' Rating '||to_char(arr(i).rating));
END LOOP;
EXCEPTION
WHEN ex_c THEN DBMS_OUTPUT.PUT_LINE('Nu exista filme sau nu exista recenzii pt filme');
END;

PROCEDURE CLIENTI_NR_RECENZII
IS
v_nume p_clienti.nume%type;
v_prenume p_clienti.prenume%type;
v_numar int;
cursor c IS
SELECT c.nume,c.prenume,count(r.id_client)
FROM p_clienti c
JOIN p_recenzii r
ON c.id_client = r.id_client
GROUP BY c.id_client,c.nume,c.prenume
ORDER BY count(r.id_client) desc;
BEGIN 
OPEN c;
LOOP
FETCH c INTO v_nume,v_prenume,v_numar;
EXIT WHEN c%notfound; 
DBMS_OUTPUT.PUT_LINE('Nume: '||v_nume||' '||v_prenume||'Numar Recenzii: '||to_char(v_numar));
END LOOP;
END;

PROCEDURE FILME_CAT(v_id p_categorii.id_categorie%type)
IS
v_id_film p_filme.id_film%type;
v_nume p_filme.nume_film%type;
cursor c IS
SELECT f.id_film,f.nume_film
FROM p_filme f
JOIN p_categorii_film c
ON c.id_film = f.id_film
WHERE c.id_categorie = v_id;
v_count int :=0;
no_exc exception;
BEGIN
OPEN c;
LOOP
FETCH c INTO v_id_film,v_nume;
EXIT WHEN c%notfound;
v_count := v_count + 1;
DBMS_OUTPUT.PUT_LINE('Id Film: '||to_char(v_id_film)||' Nume Film: ' || v_nume);
END LOOP;

IF v_count = 0 THEN
RAISE no_exc;
END IF;

EXCEPTION
WHEN no_exc THEN DBMS_OUTPUT.PUT_LINE('Nu exista filme di aceasta categorie');
END;

END;
/


--5
CREATE OR REPLACE PACKAGE pack_functii_cinema
IS

FUNCTION earliest(v_id_film p_filme.id_film%type)
RETURN TIMESTAMP;

FUNCTION total_client(v_id_client p_clienti.id_client%type)
RETURN NUMBER;

FUNCTION stergere_difuzate
RETURN INT;

END;
/

CREATE OR REPLACE PACKAGE BODY pack_functii_cinema
IS

FUNCTION earliest(v_id_film p_filme.id_film%type)
RETURN TIMESTAMP
IS
v_data TIMESTAMP;
v_count int;
BEGIN
SELECT rownum,data_vizionare
INTO v_count,v_data
FROM (SELECT data_vizionare FROM p_program ORDER BY data_vizionare)
WHERE rownum = 1;
return v_data;
END;

FUNCTION total_client(v_id_client p_clienti.id_client%type)
RETURN NUMBER
IS
v_sum NUMBER;
BEGIN
SELECT SUM(pret)
INTO v_sum
FROM p_bilet
WHERE id_client = v_id_client;
RETURN v_sum;
END;

FUNCTION stergere_difuzate
RETURN INT
IS
type t IS TABLE OF p_filme.id_film%type INDEX BY PLS_INTEGER; 
v_found int := 0;
v_count int := 0;
vec t;
BEGIN

SELECT id_film
BULK COLLECT INTO vec
FROM p_filme;

FOR i IN vec.first..vec.last
LOOP

SELECT count(p.id_vizionare)
INTO v_found
FROM p_filme f
JOIN p_program p
ON p.id_film = f.id_film
WHERE f.id_film = vec(i);

IF v_found = 0 THEN
v_count := v_count + 1;

DELETE FROM p_filme
WHERE id_film = vec(i);

END IF; 
END LOOP;
RETURN 1;
END;

END;
/
