drop table Service;
drop table Appointment;
drop table GroupT;
drop table Patient;
drop table Doctor;
drop table Assistant;
drop table Habilitation;
-----------------------------------
drop type Person_TY force;
drop type Availability_TY force;
drop type WeeklyAvt_NT force;
drop type Service_TY force;
drop type Group_TY force;
drop type Appointment_TY force;
drop type Appointment_NT force;
drop type Patient_TY force;
drop type Employee_TY force;
drop type Doctor_TY force;
drop type Assistant_TY force;
drop type Habilitation_TY force;
-------------------------------------------------------------------------------------------------------------------------------
------------------------------------------CREATE TYPE STATEMENTS---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
create or replace type Person_TY as object(
  name VARCHAR(30),
  surname VARCHAR(30),
  age INTEGER(3),
  taxcode CHAR(16),
  address CHAR(40),
  telephone_no VARCHAR(10)
)NOT FINAL NOT INSTANTIABLE;
/

create or replace type Availability_TY as object(
  day INTEGER(1),
  startime timestamp,
  endtime timestamp
)FINAL INSTANTIABLE;
/

create or replace type WeeklyAvt_NT as table of Availability_TY;
/

create or replace type Service_TY as object(
  code INTEGER,
  name VARCHAR(30),
  description clob,
  servicetype varchar(10),
  cost DECIMAL(5,2),
  VA char(1)
)FINAL INSTANTIABLE;
/

create or replace type Group_TY as object(
  ID INTEGER
)FINAL INSTANTIABLE;
/

create or replace type Appointment_TY as object(
  ID INTEGER,
  plannedatetime timestamp,
  actualdatetime timestamp,
  outcome clob,
  price decimal(8,2),
  
  groupapp REF Group_TY,
  service REF Service_TY
)FINAL INSTANTIABLE;
/

create or replace type Appointment_NT as table of ref Appointment_TY;
/

create or replace type Patient_TY UNDER Person_TY(
  ID INTEGER,
  type VARCHAR(10),
  appointments Appointment_NT
)FINAL INSTANTIABLE;
/

create or replace type Employee_TY UNDER Person_TY(
  appointments Appointment_NT
)NOT FINAL INSTANTIABLE;
/

create or replace type Doctor_TY UNDER Employee_TY(
  ID INTEGER,
  specialization VARCHAR(30),
  WeeklyAvt WeeklyAvt_NT
)FINAL INSTANTIABLE;
/

create or replace type Assistant_TY UNDER Employee_TY(
  ID INTEGER,
  levelspec VARCHAR(20),
  salary DECIMAL(6,2)
)FINAL INSTANTIABLE;
/

create or replace type Habilitation_TY as object(
  employee ref Employee_TY,
  service ref Service_TY
)FINAL INSTANTIABLE;
/
---------------------------------------------------------------------------------------------------------------------------------
------------------------------------------CREATE TABLE STATEMENTS----------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Service OF Service_TY(
  code PRIMARY KEY,
  VA not null check (VA in ('v', 'a'))
);
/

CREATE TABLE Appointment OF Appointment_TY(
  ID PRIMARY KEY,
  service NOT NULL,
  groupapp NOT NULL
);
/

CREATE TABLE GroupT OF Group_TY(
  ID PRIMARY KEY
);
/

CREATE TABLE Patient OF Patient_TY(
  ID PRIMARY KEY
) nested table appointments store as AppointmentPatTab;
/

CREATE TABLE Doctor OF Doctor_TY(
  ID PRIMARY KEY
) nested table WeeklyAvt store as WeeklyAvtDTab,
  nested table appointments store as AppointmentDocTab;
/

CREATE TABLE Assistant OF Assistant_TY(
  ID PRIMARY KEY
) nested table appointments store as AppointmentAssTab;
/

CREATE TABLE Habilitation OF Habilitation_TY;
/





-----------------------------------------------------------------------------------------------------------------------------------
------------------------------------------CREATE POPULATE PROCEDURES---------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

drop procedure POPULATE_SERVICE;
drop procedure POPULATE_PATIENT;
drop procedure POPULATE_ASSISTANT;
drop procedure POPULATE_DOCTOR;
drop procedure POPULATE_HABILITATION;
drop procedure POPULATE_GROUP;
drop procedure POPULATE_APPOINTMENT;

create or replace procedure POPULATE_SERVICE(no_services in number) as 
idx number;
visit_analysis char(1);
begin
  delete from Service;
  idx :=0;
  loop
    IF DBMS_RANDOM.VALUE > 0.50
    THEN
      visit_analysis := 'v';
    ELSE
      visit_analysis := 'a';
    END IF;
    
    INSERT INTO Service VALUES (Service_TY(
      idx,                            --CODE
      DBMS_RANDOM.STRING('A', 20),    --NAME
      NULL,         --DESCRIPTION
      DBMS_RANDOM.STRING('A', 5),    --SVCTY
      (SELECT TRUNC(DBMS_RANDOM.VALUE(20, 999), 2) FROM DUAL),
      visit_analysis
    ));
    
  idx := idx + 1;
  exit when idx = no_services;
  end loop;
end;
/
--------------------------------------------------------------------------------------------------
create or replace procedure POPULATE_PATIENT(no_patient in number) as
idx number;
begin
  delete from Patient;
  idx :=0;
  loop
    INSERT INTO Patient VALUES (Patient_TY(
      
      DBMS_RANDOM.STRING('A', 20),    --NAME
      DBMS_RANDOM.STRING('A', 20),    --SURNAME
      (SELECT TRUNC(DBMS_RANDOM.VALUE(10, 99), 0) FROM DUAL), --AGE
      DBMS_RANDOM.STRING('A', 16),    --taxcode
      DBMS_RANDOM.STRING('A', 40),    --address
     -- (SELECT TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000000, 9999999999))) FROM DUAL),   --TELNO
      DBMS_RANDOM.STRING('A', 9),    --TELNO
      idx,                            --ID
      DBMS_RANDOM.STRING('A',5 ),    --TYPE
      Appointment_NT()               --APPOINTMENT (NT)
      ));
    
    idx := idx + 1;
  exit when idx = no_patient;
  end loop;
end;
/
--------------------------------------------------------------------------------------------------
create or replace procedure POPULATE_ASSISTANT(no_customers in number) as 
idx number;

begin
  delete from Assistant;
  idx :=0;
  loop
    INSERT INTO Assistant
    VALUES (Assistant_TY(
      DBMS_RANDOM.STRING('A', 30),    --NAME
      DBMS_RANDOM.STRING('A', 30),    --SURNAME
      (SELECT TRUNC(DBMS_RANDOM.VALUE(10, 99), 2) FROM DUAL), --AGE
      DBMS_RANDOM.STRING('A', 16),    --TAXCODE
      DBMS_RANDOM.STRING('A', 30),    --ADDRESS
      (SELECT TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000000, 9999999999))) FROM DUAL),   --TELNO
      Appointment_NT(),                             --APPOINTMENTS
      idx,                              --ID
      DBMS_RANDOM.STRING('A', 10),      --LEVELSPEC
      (SELECT TRUNC(DBMS_RANDOM.VALUE(10, 4000), 2) FROM DUAL)  --SALARY
    ));
  idx := idx + 1;
  exit when idx = no_customers;
  end loop;
end;
/
--------------------------------------------------------------------------------------------------
create or replace procedure POPULATE_DOCTOR(no_customers in number) as 
idx number;

begin
  delete from Doctor;
  idx :=0; 
  loop
    INSERT INTO Doctor
    VALUES (Doctor_TY(
      DBMS_RANDOM.STRING('A', 30),    --NAME
      DBMS_RANDOM.STRING('A', 30),    --SURNAME
      (SELECT TRUNC(DBMS_RANDOM.VALUE(10, 99), 2) FROM DUAL), --AGE
      DBMS_RANDOM.STRING('A', 16),    --TAXCODE
      DBMS_RANDOM.STRING('A', 30),    --ADDRESS
      (SELECT TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000000, 9999999999))) FROM DUAL),   --TELNO
      Appointment_NT(),                             --APPOINTMENTS
      
      idx,                              --ID
      DBMS_RANDOM.STRING('A', 10),      --SPEC
      null                              --WEEKLY AVAILABILITY
    ));
  idx := idx + 1;
  exit when idx = no_customers;
  end loop;
end;
/

---------------------------------------------------------------------------------------------------

create or replace procedure POPULATE_HABILITATION(n in number) as
i number;
begin
  i := 0;
  loop
   IF DBMS_RANDOM.VALUE > 0.40
    THEN
      insert into Habilitation values ( Habilitation_TY(
      (SELECT * FROM (SELECT REF(E) FROM Doctor E ORDER BY dbms_random.value) WHERE rownum < 2),
      (SELECT * FROM (SELECT REF(S) FROM Service S ORDER BY dbms_random.value) WHERE rownum < 2)
      ));
    ELSE
      insert into Habilitation values(Habilitation_TY(
      (SELECT * FROM (SELECT REF(E) FROM Assistant E ORDER BY dbms_random.value) WHERE rownum < 2),
      (SELECT * FROM (SELECT REF(S) FROM Service S ORDER BY dbms_random.value) WHERE rownum < 2)
      )); 
   END IF;
   i:= i + 1;
  exit when i = n;
  end loop;
end;
/

--------------------------------------------------------------------------------------------------
create or replace procedure POPULATE_GROUP(no_customers in number) as 
idx number;

begin
  delete from GroupT;
  idx :=0;
  loop
    INSERT INTO GroupT VALUES (Group_TY(
      idx                            --ID
    ));
  idx := idx + 1;
  exit when idx = no_customers;
  end loop;
end;
/
------------------------------------------------------------------------------------------
create or replace procedure POPULATE_APPOINTMENT(n in number) as
i number;
g ref Group_TY;
s ref Service_TY;
ass ref Assistant_TY;
app Appointment_TY;
cus ref Patient_TY;
doc ref Doctor_TY;

begin
  delete from Appointment;
  i := 0;
  loop
   insert into Appointment values(Appointment_TY(
      i,
      (SELECT TO_DATE( TRUNC( DBMS_RANDOM.VALUE(TO_CHAR(DATE '2000-01-01','J') ,TO_CHAR(DATE '2030-12-31','J') ) ),'J' ) FROM DUAL),    --planneddatetime
      (SELECT TO_DATE( TRUNC( DBMS_RANDOM.VALUE(TO_CHAR(DATE '2000-01-01','J') ,TO_CHAR(DATE '2030-12-31','J') ) ),'J' ) FROM DUAL),   --actualdatetime
      (select dbms_random.string('A', 5) from dual),                                                    --outcome
      (select trunc(dbms_random.value(0, 5000), 2) from dual),                                          --price
      (SELECT * FROM (SELECT REF(Gr) FROM Groupt Gr ORDER BY dbms_random.value) WHERE rownum < 2),      --groupapp
      (SELECT * FROM (SELECT REF(Se) FROM Service Se ORDER BY dbms_random.value) WHERE rownum < 2)      --service
    ));
    
    SELECT * into ass FROM (SELECT REF(S) FROM Assistant S ORDER BY dbms_random.value) WHERE rownum < 2;                       --customer
    SELECT * into cus FROM (SELECT REF(S) FROM Patient S ORDER BY dbms_random.value) WHERE rownum < 2;                         --assistant
    SELECT * into doc FROM (SELECT REF(S) FROM Doctor S ORDER BY dbms_random.value) WHERE rownum < 2;                          --doctor
    
    insert into table(
      select appointments
      from Patient P
      where ref(P) = cus
    )
    select ref(Ap) from Appointment Ap where Ap.ID = i;
    
    insert into table(
      select appointments
      from Assistant P
      where ref(P) = ass
    )
    select ref(Ap) from Appointment Ap where Ap.ID = i;
    
    insert into table(
      select appointments
      from Doctor P
      where ref(P) = doc
    )
    select ref(Ap) from Appointment Ap where Ap.ID = i;
    
    i:= i + 1;
  exit when i = n;
  end loop;
end;
/

---------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------QUERY PROCEDURES-----------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
drop procedure INSERT_APPOINTMENT;
drop procedure PRINT_PATIENT;
drop procedure PRINT_SERVICE;
drop procedure PRINT_DOCTOR;
drop procedure PRINT_ASSISTANT;
drop procedure PRINT_APPONTMENT_TODAY_DOCTOR;
drop procedure PRINT_APPONTMENT_TODAY_ASS;

create or replace procedure INSERT_APPOINTMENT(ServiceID number, PatientID number, GroupNO number, actual timestamp, book timestamp) as
  i number;
  ser ref Service_TY;
  gro ref Group_TY;
  price NUMBER(5, 2); 
  begin
    select max(ID) into i from appointment;    --SELECT NEXT ID FOR APPOINTMENT
    select ref(S), S.cost into ser, price from service S 
    where S.code = ServiceID;  --REQUESTED SERVICE
    SELECT ref(Gr) into gro FROM Groupt Gr where Gr.ID = GroupNO;
    
    insert into appointment values (Appointment_TY(
         i+1, actual, book, (select dbms_random.string('A', 5) from dual) , price ,  gro ,  ser)
    );
    insert into table(
      select appointments
      from Patient P
      where P.ID = PatientID
    ) select ref(Ap) from Appointment Ap where Ap.ID = i+1;
end;
/

--------------------------------------------------------------------------------------------
create or replace procedure PRINT_PATIENT (patient_id in number) as
name varchar(30);
surname varchar(30);
age NUMBER;
service Service_TY;
appointment Appointment_TY;
appointments Appointment_NT;

begin
  select P.surname, P.name, P.age, P.appointments into surname, name, age, appointments
  from Patient P
  where P.ID = patient_id;

  dbms_output.put_line('Appointments of patient n: '|| patient_id);
  dbms_output.put_line(surname ||' '|| name ||' '|| age);

  for curs_appointment in (
    select * from table(appointments)
  ) loop
    select deref(curs_appointment.column_value) into appointment from dual;
    select deref(appointment.service) into service from dual;
    dbms_output.put_line('Patient ID: '|| patient_id || '  Outcome: '|| appointment.outcome || '  Price: '|| appointment.price || '  Booked: '|| appointment.plannedatetime || '  Actual: '|| appointment.actualdatetime);
    dbms_output.put_line('ServiceDescription: '|| service.description ||'   ServiceName: '|| service.name);
    dbms_output.new_line();
  end loop;
end;
/

--------------------------------------------------------------------------------------------
create or replace procedure PRINT_SERVICE as
service Service_TY;
appointment Appointment_TY;
begin 
  for curs_appointment in (
    select * from appointment ap
    where extract(day from cast(ap.actualdatetime as date)) = extract(day from cast(current_timestamp as date))
    )
  loop
    select deref(curs_appointment.service) into service from dual;
     dbms_output.put_line('ServiceName: '|| service.name);
    dbms_output.put_line( '  VA: '|| service.VA || '  Cost: ' || service.cost || '  Description: '|| service.description || '  Type: '|| service.servicetype);
  end loop;
end;
/

-------------------------------------------------------------------------------------------------
create or replace procedure PRINT_DOCTOR as
appointment_count integer;
begin
  for cursor_doctor in (
    select * from Doctor
  ) loop
     DBMS_OUTPUT.PUT_LINE('Doctor:  Name:' || cursor_doctor.name || '  Surname:' || cursor_doctor.surname);
     DBMS_OUTPUT.PUT_LINE( 'Age: ' || cursor_doctor.age || '  Specialization: ' || cursor_doctor.specialization );
     select count(*) into appointment_count from table(cursor_doctor.appointments);
     DBMS_OUTPUT.PUT_LINE('Number appointments: ' || appointment_count);
     DBMS_OUTPUT.PUT_LINE('');
    end loop;
end;
/

---------------------------------------------------------------------------------------------------------
create or replace procedure PRINT_ASSISTANT as
appointment_count integer;
begin
  for cursor_assistant in ( 
    select * from Assistant
   ) loop
     DBMS_OUTPUT.PUT_LINE('Assistant:   Name:' || cursor_assistant.name || '  Surname:' || cursor_assistant.surname);
     DBMS_OUTPUT.PUT_LINE('Age: ' || cursor_assistant.age || '  Level ' || cursor_assistant.levelspec ||' Salary: ' || cursor_assistant.salary );
     select count(*) into appointment_count from table(cursor_assistant.appointments);
     DBMS_OUTPUT.PUT_LINE('Number appointments: ' || appointment_count);
     DBMS_OUTPUT.PUT_LINE('');
    end loop;
end;
/

-------------------------------------------------------
create or replace procedure PRINT_APPONTMENT_TODAY_DOCTOR(doctor_id in number) as
surname varchar(30);
specialization varchar(30);
service Service_TY;
appointment Appointment_TY;
appointments Appointment_NT;

begin
  select D.surname, D.appointments into surname, appointments
  from Doctor D
  where id = doctor_id;
  dbms_output.put_line('Appointments of doctor #: '|| doctor_id || '  Surname:' || surname);

  for curs_appointment in (
    select * from table(appointments)
  ) loop
      select deref(curs_appointment.column_value) into appointment from dual;
      --if cast(appointment.actualdatetime as date) = cast(current_timestamp as date)
      --then 
        dbms_output.put_line('Planned: '|| appointment.plannedatetime || '  Actual: '|| appointment.actualdatetime);
        select deref(appointment.service) into service from dual;
        dbms_output.put_line('Service --> Name: ' || service.name ||'  Type '|| service.servicetype || '  VA '|| service.VA);
        dbms_output.put_line('');
      --end if;
  end loop;
end;
/
--------------------------------------------------------------------------------------------

create or replace procedure PRINT_APPONTMENT_TODAY_ASS(assistant_id in number) as
surname varchar(30);
specialization varchar(30);
service Service_TY;
appointment Appointment_TY;
appointments Appointment_NT;

begin
  select A.surname, A.appointments into surname, appointments
  from Assistant A
  where id = assistant_id;
  dbms_output.put_line('Appointments of assistant #: '|| assistant_id || '  Surname:' || surname);

  for curs_appointment in (
    select * from table(appointments)
  ) loop
      select deref(curs_appointment.column_value) into appointment from dual;
      --if cast(appointment.actualdatetime as date) = cast(current_timestamp as date)
      --then 
        dbms_output.put_line('Planned: '|| appointment.plannedatetime || '  Actual: '|| appointment.actualdatetime);
        select deref(appointment.service) into service from dual;
        dbms_output.put_line('Service --> Name: ' || service.name ||'  Type '|| service.servicetype || '  VA '|| service.VA);
        dbms_output.put_line('');
      --end if;
  end loop;
end;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------EXECUTION------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
exec POPULATE_SERVICE(30);
select count(*) from service;
exec POPULATE_PATIENT(2000);
select count(*) from patient;
exec POPULATE_ASSISTANT(40);
select count(*) from assistant;
exec POPULATE_DOCTOR(30);
select count(*) from doctor;
exec POPULATE_HABILITATION(210);
select count(*) from habilitation;

exec POPULATE_GROUP(2000);
select count(*) from GroupT;
exec POPULATE_APPOINTMENT(10000);
select count(*) from appointment;

--------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------TRIGGER---------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
create or replace trigger CHECK_HABILITATION
before insert on Habilitation
for each row
declare
  emp Employee_TY;
  ser Service_TY;
begin
  select deref(:new.Employee) into emp from dual;
  if (emp is of (Assistant_TY)) then
    select deref(:new.Service) into ser from dual;
    if ser.VA = 'v' then
      raise_application_error('-20001', 'ERROR! AN ASSISTANT CANNOT PERFORM A VISIT!!');
    end if;
  end if;
end;
/

create or replace trigger insertGroup
BEFORE INSERT ON Appointment
FOR EACH ROW
  DECLARE
    g Group_TY;
    gref ref Group_TY;
    gcode number;
  BEGIN
    if :NEW.ID is null then
      select max(ID) into gcode from groupt;
      g := Group_TY(gcode+1);
      insert into groupt values (g);
      select ref(gr) into gref 
      from groupt gr where ID = gcode+1;
      :NEW.groupapp := gref;
    end if;
end;
/


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------EXECUTION------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

set serveroutput on


exec INSERT_APPOINTMENT(6, 204, 34, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
exec PRINT_PATIENT(4);
exec PRINT_SERVICE;
exec PRINT_DOCTOR;
exec PRINT_ASSISTANT;

--exec PRINT_APPONTMENT_TODAY_DOCTOR(5);
--exec PRINT_APPONTMENT_TODAY_ASS(5);

--EXECUTION OF TRIGGER
insert into Habilitation values( Habilitation_TY(
    (SELECT * FROM (SELECT REF(E) FROM Assistant E ORDER BY dbms_random.value) WHERE rownum < 2),
    (SELECT * FROM (SELECT REF(S) FROM Service S ORDER BY dbms_random.value) WHERE rownum < 2)
));
/
