--- VENKATA GAYATHRI PERI---
---BUS ADM 749 ASSIGNMENT 4----

--1.	Write a function to calculate the commission a salesperson earned during a period.--
CREATE OR REPLACE FUNCTION CommissionEarned(
    salespersonid IN NUMBER,
    commission_start_date IN DATE,
    commission_end_date IN DATE
) RETURN NUMBER 
IS
    total_commission NUMBER := 0;
    FLAG NUMBER(3);
BEGIN
    -- Check if the salesperson ID exists in the Employee table
    SELECT COUNT(*) INTO FLAG
    FROM EMPLOYEE 
    WHERE ID = salespersonid;

    IF FLAG < 1 THEN
        RAISE_APPLICATION_ERROR('-20001', 'Employee ' || salespersonid || ' does not exist!');
    END IF;

    -- Check if the salesperson ID exists in the Salesperson table
    BEGIN
        SELECT 1
        INTO FLAG
        FROM Salesperson
        WHERE ID = salespersonid;

        -- If no exception is raised, the salesperson ID exists in the Salesperson table
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR('-20002', 'Employee ' || salespersonid || ' is not a salesperson!');
    END;

    -- Sum the commission for sales within the specified period
    SELECT NVL(SUM(ST.quantity * P.unitPrice * SP.commission / 100), 0)
    INTO total_commission
    FROM SALEITEM ST
    JOIN PRODUCT P ON P.UPC = ST.UPC
    JOIN SALE S ON S.INVOICENO = ST.INVOICENO
    JOIN SALESPERSON SP ON SP.ID = S.SALESPERSON
    WHERE S.SALESPERSON = salespersonid
    AND S.INVOICEDATE BETWEEN commission_start_date AND commission_end_date;

    RETURN total_commission;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR('-20003', 'An error occurred: ' || SQLERRM);
END CommissionEarned;
/

-- Use the function in queries
INSERT INTO Client (clientNo, name, salesperson)
VALUES (1001, 'Main St Hardware', 103);
INSERT INTO Client (clientNo, name, salesperson)
VALUES (1002, 'ABC Home Store', 104);
INSERT INTO Client (clientNo, name, salesperson)
VALUES (1003, 'City Hardware', 104);
INSERT INTO Client (clientNo, name, salesperson)
VALUES (1004, 'Western Hardware', 105);
INSERT INTO Client (clientNo, name, salesperson)
VALUES (1005, 'Central Store', 105);

INSERT INTO Sale
VALUES (124001, '10-NOV-2022', 103, 1001);
INSERT INTO Sale
VALUES (124002, '15-NOV-2022', 104, 1002);
INSERT INTO Sale
VALUES (124003, '20-NOV-2022', 104, 1003);
INSERT INTO Sale
VALUES (124004, '30-NOV-2022', 105, 1004);
INSERT INTO Sale
VALUES (124005, '10-DEC-2022', 105, 1005);

INSERT INTO SaleITEM
VALUES (124001, '234569', 10);
INSERT INTO SaleITEM
VALUES (124001, '235569', 10);
INSERT INTO SaleITEM
VALUES (124002, '234569', 10);
INSERT INTO SaleITEM
VALUES (124002, '338569', 50);
INSERT INTO SaleITEM
VALUES (124003, '235569', 20);
INSERT INTO SaleITEM
VALUES (124004, '238569', 10);
INSERT INTO SaleITEM
VALUES (124005, '236569', 20);
INSERT INTO SaleITEM
VALUES (124005, '237569', 10);

SELECT CommissionEarned(999, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT CommissionEarned(101, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT CommissionEarned(102, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT CommissionEarned(103, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT CommissionEarned(104, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT CommissionEarned(105, '01-JAN-2022', '31-DEC-2022') FROM DUAL;

SELECT ID, CommissionEarned(ID, '01-NOV-2022', '30-NOV-2022') AS C_NOV_2013,
	CommissionEarned(ID, '01-DEC-2022', '31-DEC-2022') AS C_DEC_2013,
	CommissionEarned(ID, '01-JAN-2022', '31-DEC-2022') AS C2013
FROM Salesperson;

SELECT SUM(CommissionEarned(ID, '01-NOV-2022', '30-NOV-2022')) AS C_NOV_2013,
	SUM(CommissionEarned(ID, '01-DEC-2022', '31-DEC-2022')) AS C_DEC_2013,
	SUM(CommissionEarned(ID, '01-JAN-2022', '31-DEC-2022')) AS C2013
FROM Salesperson;
------------------------------------------------------------------------------------------------------------------------------------

--2.	Write a trigger to check and enforce the following constraints when a new record is inserted into the Salesperson table: The supervision relationship between salespersons is hierarchical up to three levels--
CREATE OR REPLACE TRIGGER SupervisionConstraint
BEFORE INSERT ON Salesperson
FOR EACH ROW
DECLARE
    hlevel NUMBER := 0;
    mngr NUMBER := :NEW.manager;
   mngr_count NUMBER;
BEGIN
    -- Check if the manager ID exists in the Salesperson table
    SELECT COUNT(*)
    INTO mngr_count
    FROM Salesperson
    WHERE ID = mngr;

    -- If the manager does not exist, return to let the foreign key constraint handle it
    IF mngr_count = 0 THEN
        RETURN;
    END IF;

    -- If the manager is NULL, no need to perform hierarchy checks
    IF mngr IS NULL THEN
        RETURN;
    END IF;

    -- Check if the supervisor ID is within the hierarchy up to three levels using a loop
    WHILE mngr IS NOT NULL AND hlevel < 3 LOOP
        SELECT manager INTO mngr
        FROM Salesperson
        WHERE ID = mngr;

        hlevel := hlevel + 1;
    END LOOP;

    -- If the hierarchy level is greater than or equal to 3, raise an error
    IF hlevel >= 3 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Integrity Constraint Violated: The supervision relationship is hierarchical up to three levels!');
    END IF;
END;
/
--test the trigger---
--first insert into employees--
INSERT INTO Employee (ID, firstName, lastName, title, gender, officeNo, birthdate)
VALUES (
119, 'Adam', 'Baker', 'Sales Representative', 'M', 105, '7-JUL-1972'
);
INSERT INTO Employee (ID, firstName, lastName, title, gender, officeNo, birthdate)
VALUES (
120, 'Steve', 'Dickens', 'Sales Representative', 'M', 105, '7-AUG-1972'
);
INSERT INTO Employee (ID, firstName, lastName, title, gender, officeNo, birthdate)
VALUES (
121, 'Alana', 'Carlyle', 'Sales Representative', 'F', 105, '17-JUL-1992'
);

select * from Employee;
--now insert into Salesperson---
INSERT INTO Salesperson
VALUES (
119, 4142296541, 20, null
);  --no error

INSERT INTO Salesperson
VALUES (
120, 4142296542, 20, 118
); --no error

INSERT INTO Salesperson
VALUES (
121, 4142296543, 20, 999
); -- parent key not found error is expected

INSERT INTO Salesperson
VALUES (
121, 4142296543, 20, 120
); -- here 117-118-120 heirarchy done.117 is manager of 118.
--118 is manager of 120. 117-118-120, already 3 levels. 120 cannot be a manager of anyone else. So trigger should work and display error
INSERT INTO Salesperson
VALUES (
121, 4142296543, 20, 118
); -- no error
SELECT * FROM Salesperson;
----------------------------------------------------------------------------------------------------------------------------------
----3.	A salesperson is leaving CPHC. Write a procedure to make related changes in the database. 
--Pass the following responsibilities from salesperson A to salesperson B: products authorized to sell, clients, sales, payments, 
--backups, other salespersons A is a backup of, manager (if A was the manager of B), other salespersons A manages. Then delete salesperson A from the Employee and Salesperson tables. You can assume that all integrity constraints are enforced and do not need to consider them in this procedure.
CREATE OR REPLACE PROCEDURE Salesperson_Leave (
    theSalesperson  IN Salesperson.ID%TYPE,
   substituteSalesperson  IN Salesperson.ID%TYPE
) AS
    EmpA INT;
    EmpB INT;
    SalesPersonA INT;
    SalesPersonB INT;
BEGIN
    -- Check if employee A exists in the Employee table
    SELECT COUNT(*)
    INTO EmpA
    FROM Employee
    WHERE ID = theSalesperson;

    IF EmpA = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Employee ' || theSalesperson || ' does not exist!');
    END IF;

    -- Check if employee B exists in the Employee table
    SELECT COUNT(*)
    INTO EmpB
    FROM Employee
    WHERE ID = substituteSalesperson;

    IF EmpB = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Employee ' || substituteSalesperson || ' does not exist!');
    END IF;

    -- Check if employee A is a salesperson in the Salesperson table
    SELECT COUNT(*)
    INTO SalesPersonA
    FROM Salesperson
    WHERE ID = theSalesperson;

    IF SalesPersonA = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Employee ' || theSalesperson || ' is not a salesperson!');
    END IF;

    -- Check if employee B is a salesperson in the Salesperson table
    SELECT COUNT(*)
    INTO SalesPersonB
    FROM Salesperson
    WHERE ID = substituteSalesperson;

    IF SalesPersonB = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Employee ' || substituteSalesperson || ' is not a salesperson!');
    END IF;

    -- Check if salesperson A and B are the same
    IF theSalesperson = substituteSalesperson THEN
        RAISE_APPLICATION_ERROR(-20007, 'The two salespersons cannot be the same person!');
    END IF;

    -- Pass products authorized to sell
      DELETE FROM Sells
      WHERE salesperson = theSalesperson
            AND UPC IN
            (
            SELECT UPC
            FROM   Sells
            WHERE salesperson = substituteSalesperson
            );
 
      UPDATE Sells
      SET    salesperson = substituteSalesperson
      WHERE  salesperson = theSalesperson;
 

    -- Transfer clients from A to B
    UPDATE Client
    SET salesperson = substituteSalesperson
    WHERE salesperson = theSalesperson;

    -- Transfer sales from A to B
    UPDATE Sale
    SET salesperson = substituteSalesperson
    WHERE salesperson = theSalesperson;

    -- pass payments
    UPDATE Payment
    SET    receivingEmployee = substituteSalesperson
    WHERE  receivingEmployee = theSalesperson;

    -- Assuming a Backup table structure, transfer backups from A to B
    -- The specific logic will depend on the Backup table's structure
    -- Pass backups
      DELETE FROM Backup
      WHERE salesperson = theSalesperson AND backup = substituteSalesperson;
 
      DELETE FROM Backup
      WHERE salesperson = theSalesperson
            AND backup IN
            (
            SELECT backup
            FROM   Backup
            WHERE salesperson = substituteSalesperson
            );
 
      UPDATE Backup
      SET    salesperson = substituteSalesperson
      WHERE  salesperson = theSalesperson;
 
      -- Pass other salespersons A is a backup of
      DELETE FROM Backup
      WHERE salesperson = substituteSalesperson AND backup = theSalesperson;
 
      DELETE FROM Backup
      WHERE backup = theSalesperson
            AND salesperson IN
            (
            SELECT salesperson
            FROM   Backup
            WHERE backup = substituteSalesperson
            );
 
      UPDATE Backup
      SET    backup = substituteSalesperson
      WHERE  backup = theSalesperson;

      

    -- Update manager field if A was the manager of B
    UPDATE Salesperson
    SET    manager =
        (
        SELECT manager
        FROM   Salesperson
        WHERE  ID = theSalesperson
        )
    WHERE  ID = substituteSalesperson and manager = theSalesperson;

    -- Update other salespersons A manages to B
    UPDATE Salesperson
    SET manager = substituteSalesperson
    WHERE manager = theSalesperson;

    -- Delete salesperson A from Salesperson and Employee tables
    DELETE FROM Salesperson WHERE ID = theSalesperson;
    DELETE FROM Employee WHERE ID = theSalesperson;

    -- Commit the changes
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END Salesperson_Leave;
/
-- execute the procedure
UPDATE Salesperson SET manager=105 WHERE ID=103;
UPDATE Salesperson SET manager=105 WHERE ID=104;
UPDATE Salesperson SET manager=102 WHERE ID=105;

INSERT INTO Backup
VALUES (102, 103);
INSERT INTO Backup
VALUES (102, 105);
INSERT INTO Backup
VALUES (103, 104);
INSERT INTO Backup
VALUES (103, 105);
INSERT INTO Backup
VALUES (104, 105);
INSERT INTO Backup
VALUES (105, 103);
INSERT INTO Backup
VALUES (105, 104);
INSERT INTO Backup
VALUES (105, 102);

INSERT INTO ClientEmployee
VALUES (1001, 101, 'Michael', 'Smith', 'Purchase Manager');
INSERT INTO ClientEmployee
VALUES (1002, 101, 'John', 'Kaplan', 'CFO');
INSERT INTO ClientEmployee
VALUES (1003, 101, 'Beth', 'Chen', 'Purchase Manager');
INSERT INTO ClientEmployee
VALUES (1004, 101, 'Linda', 'Jones', 'Purchase Manager');
INSERT INTO ClientEmployee
VALUES (1005, 901, 'Lisa', 'Garcia', 'Purchase Manager');

INSERT INTO Payment
VALUES (700001, 124001, 103, 1001, 101, '18-NOV-2022', 'Check', 17.16);
INSERT INTO Payment
VALUES (700002, 124002, 104, 1002, 101, '19-NOV-2022', 'Credit', 100);
INSERT INTO Payment
VALUES (700003, 124005, 105, 1005, 901, '12-DEC-2022', 'Check', 33.27);

SELECT ID, firstName, lastName FROM Employee;
SELECT * FROM Salesperson;
SELECT * FROM Backup;
SELECT * FROM Sells;
SELECT * FROM Client;
SELECT * FROM Sale;
SELECT * FROM Payment;

EXECUTE Salesperson_Leave (999, 103);

EXECUTE Salesperson_Leave (105, 999);

EXECUTE Salesperson_Leave (101, 103);

EXECUTE Salesperson_Leave (105, 101);

EXECUTE Salesperson_Leave (105, 105);

EXECUTE Salesperson_Leave (105, 103);

SELECT ID, firstName, lastName FROM Employee;
SELECT * FROM Salesperson;
SELECT * FROM Backup;
SELECT * FROM Sells;
SELECT * FROM Client;
SELECT * FROM Sale;
SELECT * FROM Payment;
