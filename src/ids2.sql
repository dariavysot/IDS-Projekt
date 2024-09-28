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
    osobni_cislo VARCHAR2(20),
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

    CONSTRAINT PK_Uzivatel PRIMARY KEY(osobni_cislo),
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
    cislo_pracovnika VARCHAR2(20),

    CONSTRAINT FK_TitulInfo_Uzivatel FOREIGN KEY(cislo_pracovnika)
        REFERENCES Uzivatel(osobni_cislo)
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
    cislo_pracovnika VARCHAR2(20),

    CONSTRAINT PK_Titul PRIMARY KEY(id_titulinfo, rok_vydani),
    CONSTRAINT FK_Titul_TitulInfo FOREIGN KEY(id_titulinfo)
        REFERENCES TitulInfo(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Titul_Oddeleni FOREIGN KEY(zkratka_oddeleni)
        REFERENCES Oddeleni(zkratka_oddeleni),
    CONSTRAINT FK_Titul_Uzivatel FOREIGN KEY(cislo_pracovnika)
        REFERENCES Uzivatel(osobni_cislo)
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
    cislo_pracovnika VARCHAR2(20),
    cislo_ctenare VARCHAR2(20) NOT NULL,

    CONSTRAINT FK_Vypujcka_Titul FOREIGN KEY(id_titulinfo, rok_vydani)
        REFERENCES Titul(id_titulinfo, rok_vydani)
        ON DELETE CASCADE,
    CONSTRAINT FK_Vypujcka_Pracovnik FOREIGN KEY(cislo_pracovnika)
        REFERENCES Uzivatel(osobni_cislo)
        ON DELETE SET NULL,
    CONSTRAINT FK_Vypujcka_Ctenar FOREIGN KEY(cislo_ctenare)
        REFERENCES Uzivatel(osobni_cislo)
        ON DELETE CASCADE
);

CREATE TABLE Rezervace(
    id INT GENERATED AS IDENTITY PRIMARY KEY,
    zacatek DATE NOT NULL,
    konec DATE NOT NULL,
    id_titulinfo INT,
    rok_vydani NUMBER(4) NOT NULL,
    cislo_uzivatel VARCHAR2(20) NOT NULL,

    CONSTRAINT FK_Rezervace_Uzivatel FOREIGN KEY(cislo_uzivatel)
        REFERENCES Uzivatel(osobni_cislo)
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

INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1001', 'Jan', 'Novák', TO_DATE('1990-05-15', 'YYYY-MM-DD'), '+420123456789', 'jan.novak@example.com', 'janovak', 'heslo123', 'pracovnik', 'Programátor', 'OIT');
INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1002', 'Eva', 'Svobodová', TO_DATE('1985-09-20', 'YYYY-MM-DD'), '+420987654321', 'eva.svobodova@example.com', 'evasvob', 'svoboda', 'ctenar', NULL, 'OKN');
INSERT INTO Uzivatel (osobni_cislo, jmeno, prijmeni, datum_narozeni, tel_cislo, email, login, heslo, typ, napln_prace, zkratka_oddeleni)
    VALUES ('1003', 'Pavel', 'Doležal', TO_DATE('1992-12-10', 'YYYY-MM-DD'), '+420654321987', 'pavel.dolezal@example.com', 'paveld', 'dolezal123', 'pracovnik', 'Knihovnik', 'OAD');

INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Zdeněk', 'Ležák');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('J.K.', 'Rowling');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Javier', 'Esparza');
INSERT INTO Autor (jmeno, prijmeni)
    VALUES ('Michael', 'Blondin');

INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, cislo_pracovnika)
    VALUES ('Harry Potter', 'kniha', '978-0-54-501022-1', 'Angličtina', '1002');
INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, cislo_pracovnika)
    VALUES ('ABC', 'casopis', '977-1-21-048800-2', 'Čeština', '1003');
INSERT INTO TitulInfo (nazev, typ, ISBN, jazyk, cislo_pracovnika)
    VALUES ('Automata Theory: An Algorithmic Approach', 'kniha', '978-0-26-204863-7', 'Angličtina', '1001');

INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (1, 2);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (2, 1);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (3, 3);
INSERT INTO Autor_TitulInfo (id_autor, id_titulinfo)
    VALUES (4, 3);

INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, cislo_pracovnika)
    VALUES (1, 2007, TO_DATE('2007-10-01', 'YYYY-MM-DD'), 'Dobrý', 'Bloomsbury', 'OKN', '1003');
INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, cislo_pracovnika)
    VALUES (2, 1997, TO_DATE('1997-06-26', 'YYYY-MM-DD'), 'Výborný', 'Scholastic', 'OKN', '1003');
INSERT INTO Titul (id_titulinfo, rok_vydani, datum_pridani, stav_titulu, nakladatelstvi, zkratka_oddeleni, cislo_pracovnika)
    VALUES (3, 2017, TO_DATE('2017-04-15', 'YYYY-MM-DD'), 'Výborný', 'Simon & Schuster', 'OIT', '1001');

INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, cislo_pracovnika, cislo_ctenare)
    VALUES (TO_DATE('2024-03-20', 'YYYY-MM-DD'), TO_DATE('2024-04-20', 'YYYY-MM-DD'), NULL, 'Dobrý', NULL, 1, 2007, '1003', '1002');
INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, cislo_pracovnika, cislo_ctenare)
    VALUES (TO_DATE('2024-03-21', 'YYYY-MM-DD'), TO_DATE('2024-04-21', 'YYYY-MM-DD'), TO_DATE('2024-04-10', 'YYYY-MM-DD'), 'Výborný', 'Špatný (ohlé rohy)', 2, 1997, '1003', '1002');
INSERT INTO Vypujcka (datum_vypujceni, vratit_do, datum_vraceni, stav_pred, stav_po, id_titulinfo, rok_vydani, cislo_pracovnika, cislo_ctenare)
    VALUES (TO_DATE('2024-03-22', 'YYYY-MM-DD'), TO_DATE('2024-04-22', 'YYYY-MM-DD'), NULL, 'Výborný', NULL, 3, 2017, '1001', '1002');

INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, cislo_uzivatel)
    VALUES (TO_DATE('2024-03-24', 'YYYY-MM-DD'), TO_DATE('2024-03-30', 'YYYY-MM-DD'), 2, 1997, '1002');
INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, cislo_uzivatel)
    VALUES (TO_DATE('2024-03-25', 'YYYY-MM-DD'), TO_DATE('2024-03-31', 'YYYY-MM-DD'), 3, 2017, '1002');
INSERT INTO Rezervace (zacatek, konec, id_titulinfo, rok_vydani, cislo_uzivatel)
    VALUES (TO_DATE('2024-03-26', 'YYYY-MM-DD'), TO_DATE('2024-04-01', 'YYYY-MM-DD'), 1, 2007, '1002');

-- Spolecna tabulka pro Aktivní vypujcky a Rezervováne titulu 
WITH VypujckyRezervace AS (
    SELECT 
        'Vypujcka' AS typ,
        v.id AS id,
        v.datum_vypujceni AS zacatek,
        v.vratit_do AS konec,
        v.stav_po AS stav,
        v.id_titulinfo AS id_titulinfo,
        v.rok_vydani AS rok_vydani,
        v.cislo_ctenare AS cislo_uzivatel
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
        NULL AS stav,
        r.id_titulinfo AS id_titulinfo,
        r.rok_vydani AS rok_vydani,
        r.cislo_uzivatel AS cislo_uzivatel
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
    vr.stav,
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
    LEFT JOIN Uzivatel u ON vr.cislo_uzivatel = u.osobni_cislo
WHERE 
    (vr.typ = 'Vypujcka') OR
    (vr.typ = 'Rezervace'); -- Додана умова для зарезервованих книг
