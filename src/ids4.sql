DROP TABLE Rezervace;
DROP TABLE Vypujcka;
DROP TABLE Titul;
DROP TABLE Autor_TitulInfo;
DROP TABLE TitulInfo;
DROP TABLE Autor;
DROP TABLE Uzivatel;
DROP TABLE Oddeleni;

-- Zde jsme přidali atribut `zkratka_oddeleni`, protože dává větší smysl referovat
-- na oddělení zkratkou místo celého jména.
CREATE TABLE Oddeleni(
    zkratka_oddeleni NCHAR(3),
    nazev NVARCHAR2(32),
    lokace NVARCHAR2(20),

    CONSTRAINT PK_Oddeleni PRIMARY KEY(zkratka_oddeleni)
);

-- Pro realizaci generalizace jsme se rozhodli udělat pouze jednu tabulku, která
-- obsahuje všechny data a typ k rozlišení uživatele. Důvodem je, že obě specializace
-- mají pouze jeden atribut a vztahy vedou ke všem typům uživatele.
CREATE TABLE Uzivatel (
    id INT GENERATED AS IDENTITY PRIMARY KEY,       --- Explicitní vytvoření indexu pro optimalizaci.
    osobni_cislo VARCHAR2(20) UNIQUE,
    jmeno NVARCHAR2(64) NOT NULL,
    prijmeni NVARCHAR2(64) NOT NULL,
    datum_narozeni DATE,
    tel_cislo VARCHAR2(20),
    email VARCHAR2(100) CHECK (email LIKE('%@%')),
    login VARCHAR2(32),
    heslo VARCHAR2(64),

    typ VARCHAR2(10) CHECK(typ IN ('pracovnik', 'ctenar')),
    napln_prace NVARCHAR2(100),
    datum_registrace DATE DEFAULT SYSDATE,

    zkratka_oddeleni NCHAR(3) NOT NULL,

    CONSTRAINT FK_Uzivatel_Oddeleni FOREIGN KEY(zkratka_oddeleni)
        REFERENCES Oddeleni(zkratka_oddeleni)
);

CREATE TABLE Autor (
    id INT GENERATED AS IDENTITY PRIMARY KEY,
    jmeno NVARCHAR2(64) NOT NULL,
    prijmeni NVARCHAR2(64)
);

CREATE TABLE TitulInfo(
    id INT GENERATED AS IDENTITY PRIMARY KEY,
    nazev NVARCHAR2(200) NOT NULL,
    typ VARCHAR2(10) CHECK(typ IN ('casopis', 'kniha')) NOT NULL,
    ISBN VARCHAR2(17) CHECK(REGEXP_LIKE(ISBN, '([0-9]|-){17}')),
    jazyk NVARCHAR2(58) NOT NULL,
    id_pracovnika INT,

    CONSTRAINT FK_TitulInfo_Uzivatel FOREIGN KEY(id_pracovnika)
        REFERENCES Uzivatel(id)
        ON DELETE SET NULL
);

CREATE TABLE Autor_TitulInfo(
    id_autor INT,
    id_titulinfo INT,

    CONSTRAINT PK_Autor_TitulInfo PRIMARY KEY(id_autor, id_titulinfo),
    CONSTRAINT FK_Autor_TitulInfo_Autor FOREIGN KEY(id_autor)
        REFERENCES Autor(id),
    CONSTRAINT FK_Autor_TitulInfo_TitulInfo FOREIGN KEY(id_titulinfo)
        REFERENCES TitulInfo(id)
);

CREATE TABLE Titul(
    id_titulinfo INT,
    rok_vydani NUMBER(4) NOT NULL,
    datum_pridani DATE NOT NULL,
    stav_titulu NVARCHAR2(20) NOT NULL,
    nakladatelstvi NVARCHAR2(100) NOT NULL,
    zkratka_oddeleni NCHAR(3) NOT NULL,
    id_pracovnika INT,

    CONSTRAINT PK_Titul PRIMARY KEY(id_titulinfo, rok_vydani),
    CONSTRAINT FK_Titul_TitulInfo FOREIGN KEY(id_titulinfo)
        REFERENCES TitulInfo(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Titul_Oddeleni FOREIGN KEY(zkratka_oddeleni)
        REFERENCES Oddeleni(zkratka_oddeleni),
    CONSTRAINT FK_Titul_Uzivatel FOREIGN KEY(id_pracovnika)
        REFERENCES Uzivatel(id)
        ON DELETE SET NULL
);

CREATE TABLE Vypujcka(
    id INT GENERATED AS IDENTITY PRIMARY KEY,
    datum_vypujceni DATE NOT NULL,
    vratit_do DATE NOT NULL,
    datum_vraceni DATE,
    stav_pred NVARCHAR2(64),
    stav_po NVARCHAR2(64),
    id_titulinfo INT,
    rok_vydani NUMBER(4) NOT NULL,
    id_pracovnika INT,
    id_ctenare INT NOT NULL,

    CONSTRAINT FK_Vypujcka_Titul FOREIGN KEY(id_titulinfo, rok_vydani)
        REFERENCES Titul(id_titulinfo, rok_vydani)
        ON DELETE CASCADE,
    CONSTRAINT FK_Vypujcka_Pracovnik FOREIGN KEY(id_pracovnika)
        REFERENCES Uzivatel(id)
        ON DELETE SET NULL,
    CONSTRAINT FK_Vypujcka_Ctenar FOREIGN KEY(id_ctenare)
        REFERENCES Uzivatel(id)
        ON DELETE CASCADE
);

CREATE TABLE Rezervace(
    id INT GENERATED AS IDENTITY PRIMARY KEY,
    zacatek DATE NOT NULL,
    konec DATE NOT NULL,
    id_titulinfo INT,
    rok_vydani NUMBER(4) NOT NULL,
    id_uzivatel INT NOT NULL,

    CONSTRAINT FK_Rezervace_Uzivatel FOREIGN KEY(id_uzivatel)
        REFERENCES Uzivatel(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Rezervace_Titul FOREIGN KEY(id_titulinfo, rok_vydani)
        REFERENCES Titul(id_titulinfo, rok_vydani)
        ON DELETE CASCADE
);

INSERT INTO Oddeleni (zkratka_oddeleni, nazev, lokace)
    VALUES ('OIT', 'Informační technologie', 'Budova A');
INSERT INTO Oddeleni (zkratka_oddeleni, nazev, lokace)
    VALUES ('OAD', 'Administrativa', 'Budova B');
INSERT INTO Oddeleni (zkratka_oddeleni, nazev, lokace)
    VALUES ('OKN', 'Knihovna', 'Budova C');

-- Funkce pro ulehčení získání ID uživatele.
CREATE OR REPLACE FUNCTION UzivId(osobni_cislo VARCHAR) 
RETURN INT
IS
    CURSOR c_osobni_cislo(cislo VARCHAR) IS 
    SELECT id
    FROM Uzivatel U 
    WHERE U.osobni_cislo = cislo;

    r_uziv c_osobni_cislo%ROWTYPE;
BEGIN
    OPEN c_osobni_cislo(osobni_cislo);
    FETCH c_osobni_cislo INTO r_uziv;

    IF c_osobni_cislo%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Uživatel s daným osobním číslem neexistuje');
    END IF;

    CLOSE c_osobni_cislo;
    
    RETURN r_uziv.id;
END;
/

INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1001', 'Jan', 'Novák', TO_DATE('1990-05-15', 'YYYY-MM-DD'), '+420123456789', 'jan.novak@example.com', 'janovak', 'heslo123', 'pracovnik', 'Programátor', 'OIT');
INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1002', 'Eva', 'Svobodová', TO_DATE('1985-09-20', 'YYYY-MM-DD'), '+420987654321', 'eva.svobodova@example.com', 'evasvob', 'svoboda', 'ctenar', NULL, 'OKN');
INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1003', 'Pavel', 'Doležal', TO_DATE('1992-12-10', 'YYYY-MM-DD'), '+420654321987', 'pavel.dolezal@example.com', 'paveld', 'dolezal123', 'pracovnik', 'Knihovnik', 'OAD');
INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1004', 'Tomáš', 'Dřízal', TO_DATE('1982-02-10', 'YYYY-MM-DD'), '+420123654789', 'tomas.drizal@gmail.com', 'tomasd', 'tomik123', 'ctenar', 'Knihovnik', 'OKN');

INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Zdeněk', 'Ležák');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('J.K.', 'Rowling');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Javier', 'Esparza');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Michael', 'Blondin');

INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, id_pracovnika)
    VALUES ('Harry Potter', 'kniha', '978-0-54-501022-1', 'Angličtina', UzivId('1002'));
INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, id_pracovnika)
    VALUES ('ABC', 'casopis', '977-1-21-048800-2', 'Čeština', UzivId('1003'));
INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, id_pracovnika)
    VALUES ('Automata Theory: An Algorithmic Approach', 'kniha', '978-0-26-204863-7', 'Angličtina', UzivId('1001'));

INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (1, 2);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (2, 1);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (3, 3);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (4, 3);

INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, id_pracovnika)
    VALUES (1, 2007, TO_DATE('2007-10-01', 'YYYY-MM-DD'), 'Dobrý', 'Bloomsbury', 'OKN', UzivId('1003'));
INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, id_pracovnika)
    VALUES (2, 1997, TO_DATE('1997-06-26', 'YYYY-MM-DD'), 'Výborný', 'Scholastic', 'OKN', UzivId('1003'));
INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, id_pracovnika)
    VALUES (3, 2017, TO_DATE('2017-04-15', 'YYYY-MM-DD'), 'Výborný', 'Simon & Schuster', 'OIT', UzivId('1001'));

INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, id_pracovnika, id_ctenare)
    VALUES (TO_DATE('2024-03-20', 'YYYY-MM-DD'), TO_DATE('2024-04-20', 'YYYY-MM-DD'), NULL, 'Dobrý', NULL, 1, 2007, UzivId('1003'), UzivId('1002'));
INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, id_pracovnika, id_ctenare)
    VALUES (TO_DATE('2024-03-21', 'YYYY-MM-DD'), TO_DATE('2024-04-21', 'YYYY-MM-DD'), TO_DATE('2024-04-10', 'YYYY-MM-DD'), 'Výborný', 'Špatný (ohlé rohy)', 2, 1997, UzivId('1003'), UzivId('1002'));
INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, id_pracovnika, id_ctenare)
    VALUES (TO_DATE('2024-03-22', 'YYYY-MM-DD'), TO_DATE('2024-04-22', 'YYYY-MM-DD'), NULL, 'Výborný', NULL, 3, 2017, UzivId('1001'), UzivId('1002'));

INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, id_uzivatel)
    VALUES (TO_DATE('2024-03-24', 'YYYY-MM-DD'), TO_DATE('2024-03-30', 'YYYY-MM-DD'), 2, 1997, UzivId('1002'));
INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, id_uzivatel)
    VALUES (TO_DATE('2024-03-25', 'YYYY-MM-DD'), TO_DATE('2024-03-31', 'YYYY-MM-DD'), 3, 2017, UzivId('1002'));
INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, id_uzivatel)
    VALUES (TO_DATE('2024-03-26', 'YYYY-MM-DD'), TO_DATE('2024-04-01', 'YYYY-MM-DD'), 1, 2007, UzivId('1002'));
INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, id_uzivatel)
    VALUES (TO_DATE('2024-04-01', 'YYYY-MM-DD'), TO_DATE('2024-04-02', 'YYYY-MM-DD'), 1, 2007, UzivId('1004'));

-- Automatické doplnění datumu do tabulky rezervací
CREATE OR REPLACE TRIGGER rezervace_before_insert
BEFORE INSERT ON REZERVACE
FOR EACH ROW
DECLARE
    datum_dneska DATE := CURRENT_DATE;
    pocet_vypujcek INT;
BEGIN
    SELECT COUNT(*) INTO pocet_vypujcek FROM VYPUJCKA V
        WHERE V.id_titulinfo = :NEW.id_titulinfo AND V.ROK_VYDANI = :NEW.rok_vydani AND V.DATUM_VRACENI IS NULL;

    IF pocet_vypujcek > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nelze vytvořit rezervaci pro titul, který je již vypůjčený.');
    ELSE
        :NEW.zacatek := datum_dneska;
        :NEW.konec := datum_dneska + 14;
    END IF;
END;
/

-- Vytvoření rezervace pro demonstraci triggeru
INSERT INTO REZERVACE (id_titulinfo, rok_vydani, id_uzivatel) VALUES(1, 2007, UzivId('1001'));   -- Neuspech
INSERT INTO REZERVACE (id_titulinfo, rok_vydani, id_uzivatel) VALUES(2, 1997, UzivId('1002'));   -- Uspech

-- Přidání české knihy s automatickým přidáním autora a titul info pokud neexistují.
CREATE OR REPLACE PROCEDURE PridatKnihuCz(
    nazev NVARCHAR2,
    isbn VARCHAR2,
    rok_vydani INT,
    nakladatelstvi NVARCHAR2,
    zkratka_oddeleni NCHAR,
    jmeno_autora NVARCHAR2,
    id_pracovnik INT)
IS
    CURSOR c_titulinfo(Nazev VARCHAR2, ISBN VARCHAR2) IS
        SELECT * FROM TitulInfo T 
        WHERE 
            T.NAZEV = Nazev AND
            T.ISBN = ISBN AND 
            T.JAZYK = 'Čeština' AND
            T.TYP = 'kniha';
    CURSOR c_autor(cele_jmeno NVARCHAR2) IS
        SELECT * FROM Autor A
        WHERE CONCAT(A.JMENO, CONCAT(' ', A.PRIJMENI)) = cele_jmeno;
    r_titulinfo c_titulinfo%ROWTYPE;
    r_autor c_autor%ROWTYPE;
    n_autor_titulinfo INT := 0;

    v_name_list NVARCHAR2(200);
    v_separator_index INT;
BEGIN
    SET TRANSACTION NAME 'nova_kniha';

    -- Vytvoření autora pokud je to poteřba
    OPEN c_autor(jmeno_autora);
    FETCH c_autor INTO r_autor;
    IF c_autor%NOTFOUND THEN
        INSERT INTO Autor(jmeno, prijmeni) VALUES (
            SUBSTR(jmeno_autora, 0, INSTR(jmeno_autora, ' ') - 1),
            SUBSTR(jmeno_autora, INSTR(jmeno_autora, ' ') + 1)
        );
        CLOSE c_autor;
        OPEN c_autor(jmeno_autora);
        FETCH c_autor INTO r_autor;
        IF c_autor%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-10001, 'Internal erorr. CAnnot find inserted Autor.');
        END IF;
    END IF;
    CLOSE c_autor;

    -- Vytoření TitulInfo pokud je to potřeba
    OPEN c_titulinfo(nazev, isbn);
    FETCH c_titulinfo INTO r_titulinfo;
    IF c_titulinfo%NOTFOUND THEN
        INSERT INTO TitulInfo(nazev, typ, ISBN, jazyk, id_pracovnika)
            VALUES (nazev, 'kniha', isbn, 'Čeština', id_pracovnik);
        CLOSE c_titulinfo;
        OPEN c_titulinfo(nazev, isbn);
        FETCH c_titulinfo INTO r_titulinfo;
        if c_titulinfo%NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-10001, 'Internal error. Cannot find inserted TitulInfo.');
        END IF;
    END IF;
    CLOSE c_titulinfo;

    -- Vyvoření vstahu mezi autorem a titulem, pokud potřeba
    SELECT COUNT(*) INTO n_autor_titulinfo FROM Autor_TitulInfo A
        WHERE A.ID_AUTOR = r_autor.id AND A.ID_TITULINFO = r_titulinfo.id;
    IF n_autor_titulinfo = 0 THEN
        INSERT INTO AUTOR_TITULINFO(id_autor, id_titulinfo) VALUES (r_autor.id, r_titulinfo.id);
    END IF;

    -- Vložení titulu
    INSERT INTO Titul(id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, id_pracovnika)
    VALUES (r_titulinfo.id, rok_vydani, CURRENT_DATE, 'Nový', nakladatelstvi, zkratka_oddeleni, id_pracovnik);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Přidání nového titulu
BEGIN PridatKnihuCz('Začínáme programovat v jazyku Python', '978-8-02-713609-4', 2021, 'Grada', 'OIT', 'Rudolf Pecinovský', UzivId('1001')); END;
/
-- Přidání pouze nového vydání.
BEGIN 
    PridatKnihuCz('Začínáme programovat v jazyku Python', '978-8-02-713609-4', 2022, 
                  'Grada2', 'OIT', 'Rudolf Pecinovský', UzivId('1001')); 
END;
/

-- Procedura pro vypůjčení daného titulu s dokončením rezervace. Také se zde kontroluje zdali uživatel nemá již
-- vypůjčené jiné vydání dané knihy.
CREATE OR REPLACE PROCEDURE VypujckaTitulu (
    datum_vypujceni DATE,
    stav_pred NVARCHAR2,
    id_titulinfo INT,
    rok_vydani NUMBER,
    pracovnik_id INT,
    uzivatel_id INT)
IS
    CURSOR c_rezervace(id_titulinfo INT, rok_vydani NUMBER, uzivatel_id INT) IS
        SELECT *
        FROM Rezervace R
        WHERE R.id_titulinfo = id_titulinfo AND R.rok_vydani = rok_vydani AND R.konec < CURRENT_DATE;
    r_rezervace c_rezervace%ROWTYPE;

    pracovnik_id_cnt INT := 0;
BEGIN
    -- Kontrola jestli pracovnik_id je orpavdu pracovník.
    SELECT COUNT(*) INTO pracovnik_id_cnt FROM Uzivatel U
        WHERE U.id = pracovnik_id AND U.typ = 'pracovnik';
    IF pracovnik_id_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'pracovnik_id musí být Id pracovníka.');
    END IF;

    OPEN c_rezervace(id_titulinfo, rok_vydani, uzivatel_id);
    SET TRANSACTION NAME 'vypujcka';

    -- Nalezení rezervace a její případné ukončení + kontrola jestli nemá někdo jiný zarezervovaný titul.
    FETCH c_rezervace INTO r_rezervace;
    if c_rezervace%FOUND THEN
        IF r_rezervace.id_uzivatel != uzivatel_id THEN
            RAISE_APPLICATION_ERROR(-20004, 'Nelze vypůjčit titul, který má zarezervovaný jiný uživatel.');
            ROLLBACK;
        END IF;
        -- Nastavení konce rezervace.
        UPDATE Rezervace SET konec = CURRENT_DATE WHERE id = r_rezervace.id;
    END IF;

    -- Vytvoření výpůjčky
    INSERT INTO Vypujcka (
        datum_vypujceni, vratit_do, stav_pred, id_titulinfo,
        rok_vydani, id_pracovnika, id_ctenare
    ) VALUES (
        CURRENT_DATE, CURRENT_DATE + 30, stav_pred, id_titulinfo, 
        rok_vydani, pracovnik_id, uzivatel_id
    );

    COMMIT;
    CLOSE c_rezervace;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Trigger aktualizuje stav knihy na základě akcí, které proběhnou v tabulce vydávání knih
CREATE OR REPLACE TRIGGER update_book_status
AFTER INSERT OR UPDATE ON VYPUJCKA
FOR EACH ROW
DECLARE
    book_status VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        UPDATE TITUL
        SET stav_titulu = :NEW.stav_po
        WHERE id_titulinfo = :NEW.id_titulinfo AND rok_vydani = :NEW.rok_vydani;
    ELSIF UPDATING THEN
        IF :NEW.stav_po <> :OLD.stav_po THEN
            UPDATE Titul
            SET stav_titulu = :NEW.stav_po
            WHERE id_titulinfo = :NEW.id_titulinfo AND rok_vydani = :NEW.rok_vydani;
        END IF;
    END IF;
END;
/

-- Vložení nového záznamu o vydání knihy pro demonstraci triggeru
INSERT INTO VYPUJCKA (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, id_pracovnika, id_ctenare)
VALUES (TO_DATE('2024-04-25', 'YYYY-MM-DD'), TO_DATE('2024-05-25', 'YYYY-MM-DD'), TO_DATE('2024-05-25', 'YYYY-MM-DD'), 'Výborný', 'Poškozená', 1, 2007, UzivId('1003'), UzivId('1002'));

-- Aktualizace záznamu o vrácení knihy
UPDATE VYPUJCKA
SET datum_vraceni = TO_DATE('2024-05-05', 'YYYY-MM-DD'), stav_pred = 'Výborný', stav_po = 'Poškozená'
WHERE id = 1;

SELECT * FROM Titul WHERE id_titulinfo = 1 AND rok_vydani = 2007;

SELECT * FROM Titul;

-- automaticky generuje přihlašovací jméno uživatele na základě jeho jména a příjmení
CREATE OR REPLACE TRIGGER generate_user_login
BEFORE INSERT ON Uzivatel
REFERENCING NEW AS NEW
FOR EACH ROW
BEGIN
    :NEW.login := LOWER(SUBSTR(:NEW.jmeno || :NEW.prijmeni, 1, 6));

    DECLARE
        login_count INT;
    BEGIN
        SELECT COUNT(*) INTO login_count
        FROM Uzivatel
        WHERE login = :NEW.login;

        IF login_count > 0 THEN
            :NEW.login := :NEW.login || TO_CHAR(:NEW.id);
        END IF;
    END;
END;
/

-- Vložení nového uživatele s daty
INSERT INTO Uzivatel (OSOBNI_CISLO, jmeno, prijmeni, datum_narozeni, tel_cislo, email, typ, napln_prace, zkratka_oddeleni)
VALUES ('1006','Olaf', 'Smith', TO_DATE('1995-08-20', 'YYYY-MM-DD'), '+420987654321', 'petro.ivanov@example.com', 'pracovnik', 'Programátor', 'OIT');
INSERT INTO Uzivatel (OSOBNI_CISLO, jmeno, prijmeni, datum_narozeni, tel_cislo, email, typ, napln_prace, zkratka_oddeleni)
VALUES ('1007', 'Olaf', 'Smith', TO_DATE('1995-10-20', 'YYYY-MM-DD'), '+420987664321', 'petro.ivanov@example.com', 'pracovnik', 'Programátor', 'OIT');
INSERT INTO Uzivatel (OSOBNI_CISLO, jmeno, prijmeni, datum_narozeni, tel_cislo, email, typ, napln_prace, zkratka_oddeleni)
VALUES ('1008','Petro', 'Ivanov', TO_DATE('1995-08-20', 'YYYY-MM-DD'), '+420987654321', 'petro.ivanov@example.com', 'pracovnik', 'Programátor', 'OIT');

SELECT *
FROM Uzivatel
WHERE jmeno = 'Olaf';
SELECT *
FROM Uzivatel
WHERE jmeno = 'Petro';

-- Tento dotaz získává informace o aktivních výpůjčkách a rezervacích titulů.
WITH VypujckyRezervace AS (
    SELECT 
        'Vypujcka' AS typ,
        v.id AS id,
        v.datum_vypujceni AS zacatek,
        v.vratit_do AS konec,
        v.id_titulinfo AS id_titulinfo,
        v.rok_vydani AS rok_vydani,
        v.id_ctenare AS id_uzivatel
    FROM 
        Vypujcka v
    WHERE 
        v.datum_vraceni IS NULL
    UNION ALL
    SELECT 
        'Rezervace' AS typ,
        r.id AS id,
        r.zacatek AS zacatek,
        r.konec AS konec,
        r.id_titulinfo AS id_titulinfo,
        r.rok_vydani AS rok_vydani,
        r.id_uzivatel AS id_uzivatel
    FROM 
        Rezervace r
    WHERE 
        r.zacatek <= SYSDATE
)
SELECT 
    vr.typ,
    vr.id,
    vr.zacatek,
    vr.konec,
    t.nazev AS nazev_titulu,
    t.typ AS typ_titulu,
    t.jazyk AS jazyk_titulu,
    u.jmeno || ' ' || u.prijmeni AS jmeno_uzivatele,
    CASE
        WHEN vr.typ = 'Vypujcka' THEN 'Aktivní'
        WHEN vr.typ = 'Rezervace' THEN 'Rezervováno'
    END AS stav_titulu
FROM 
    VypujckyRezervace vr
    INNER JOIN TitulInfo t ON vr.id_titulinfo = t.id
    LEFT JOIN Uzivatel u ON vr.id_uzivatel = u.id
WHERE 
    (vr.typ = 'Vypujcka' ) OR
    (vr.typ = 'Rezervace'); -- Tento dotaz získává informace o aktivních výpůjčkách a rezervacích titulů.

-- Zobrazit všechny tituly s informacemi
DROP MATERIALIZED VIEW VSECHNYTITULY;
CREATE MATERIALIZED VIEW VsechnyTituly AS
    SELECT
        T.ROK_VYDANI,
        T.DATUM_PRIDANI,
        T.NAKLADATELSTVI,
        I.NAZEV,
        I.ISBN,
        I.JAZYK
    FROM Titul T
    JOIN TitulInfo I ON T.id_titulinfo = I.id
    ORDER BY T.id_titulinfo, T.rok_vydani;

-- Oprávnění
GRANT ALL ON "REZERVACE" TO XVYSOT00;
GRANT ALL ON "VSECHNYTITULY" TO XVYSOT00;

-- Vytvoření plánu pro dotat: Počet knih a časopisů autora, který má křestní jmémno Michael
EXPLAIN PLAN FOR
SELECT
    A.JMENO || ' ' || A.PRIJMENI AS jmeno_prijmeni,
    COUNT(CASE WHEN I.TYP = 'kniha' THEN 1 END) pocet_knih,
    COUNT(CASE WHEN I.TYP = 'casopis' THEN 1 END) pocet_casopisu
FROM AUTOR A
    JOIN AUTOR_TITULINFO AT ON A.ID = AT.ID_AUTOR
    JOIN TITULINFO I ON AT.ID_TITULINFO = I.ID
GROUP BY A.JMENO, A.PRIJMENI
HAVING A.JMENO = 'Michael'
ORDER BY A.JMENO, A.PRIJMENI;
-- Zobrazení vytvořeného dotazu.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Vylepšení 1
EXPLAIN PLAN FOR
SELECT
    A.ID,
    A.JMENO || ' ' || A.PRIJMENI AS jmeno_prijmeni,
    COUNT(CASE WHEN I.TYP = 'kniha' THEN 1 END) pocet_knih,
    COUNT(CASE WHEN I.TYP = 'casopis' THEN 1 END) pocet_casopisu
FROM (SELECT * FROM Autor WHERE Autor.JMENO = 'Michael') A
    JOIN AUTOR_TITULINFO AT ON A.ID = AT.ID_AUTOR
    JOIN TITULINFO I ON AT.ID_TITULINFO = I.ID
GROUP BY A.ID, A.JMENO, A.PRIJMENI
ORDER BY A.JMENO, A.PRIJMENI;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Vylepšení 2
EXPLAIN PLAN FOR
SELECT 
    S.id,
    A2.jmeno || ' ' || A2.prijmeni AS jmeno_prijmeni,
    S.pocet_knih, S.pocet_casopisu
FROM 
    Autor A2
    JOIN (
        SELECT
            A.ID,
            COUNT(CASE WHEN I.TYP = 'kniha' THEN 1 END) pocet_knih,
            COUNT(CASE WHEN I.TYP = 'casopis' THEN 1 END) pocet_casopisu
        FROM (SELECT * FROM Autor WHERE Autor.JMENO = 'Michael') A
            JOIN AUTOR_TITULINFO AT ON A.ID = AT.ID_AUTOR
            JOIN TITULINFO I ON AT.ID_TITULINFO = I.ID
        GROUP BY A.ID
        ORDER BY A.ID
    ) S ON A2.ID = S.ID;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);