create or replace package body video_pkg
IS 

--private
PROCEDURE exception_handler(
  err_code number,
  err_location varchar)
  IS
    BEGIN
     CASE err_code
        WHEN -1 THEN RAISE_APPLICATION_ERROR(-20111,'Error: Duplicate Member_ID attempted with '|| 
        err_location|| ' procedure.',FALSE);
        WHEN -2292 THEN RAISE_APPLICATION_ERROR(-20112,'Error: Editing Member_ID, Copy_ID, or 
        Title_ID with foreign values with '|| err_location|| ' procedure.',FALSE);
        WHEN +100 THEN RAISE_APPLICATION_ERROR(-20113,'Error: Data not found with '|| 
        err_location|| ' procedure.',FALSE);
     END CASE;
END exception_handler;

--private
PROCEDURE isMember(
p_member_id MEMBER.MEMBER_ID%TYPE,
err_code OUT number,
p_isMember OUT Boolean
)
IS
v_mem_id member.member_id%TYPE;
BEGIN
  SELECT member_id INTO v_mem_id FROM MEMBER
  WHERE member_id=p_member_id;
  p_isMember:=TRUE;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
   err_code:=SQLCODE;
   p_isMember:=FALSE;
  WHEN OTHERS THEN
   err_code:=SQLCODE;
   p_isMember:=FALSE;
END isMember;


--private
PROCEDURE get_copy_status(
p_title_id IN title.title_id%TYPE,
p_check_status OUT BOOLEAN
)
IS
v_status VARCHAR(25):='AVAILABLE';
availabe_copy number := 0;
foriegn_key_viloation EXCEPTION;
PRAGMA EXCEPTION_INIT (foriegn_key_viloation,-2292);
BEGIN
  --find number of "AVAILABLE' copies
  SELECT COUNT(*) INTO availabe_copy FROM TITLE_COPY
  WHERE TITLE_COPY.TITLE_ID=p_title_id AND TITLE_COPY.STATUS=v_status
  GROUP BY TITLE_ID;
  
  IF availabe_copy = 0 THEN
    p_check_status:= FALSE;
  ELSE
    p_check_status:= TRUE;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
   raise_application_error(-20114,'Error: Title_id'||' '||p_title_id||' '||'not found',False);
  WHEN foriegn_key_viloation THEN
   raise_application_error(-20114,'Error: Title_id'||' '||p_title_id||' '||'not found',False);
  WHEN others then
    raise_application_error(-20115,'Error occured with checking status of copies',False);

END get_copy_status;

--private
PROCEDURE reserve_movie(
  p_mem_id member.member_id%type,
  p_title_id title.title_id%type)
  IS
    v_copy_status boolean;
    v_copy_id number;
    v_reserve_times number;
    BEGIN
    get_copy_status(p_title_id,v_copy_status);

    IF v_copy_status=FALSE THEN
      SELECT COUNT(*) INTO v_reserve_times FROM RESERVATION
      WHERE TITLE_ID = p_title_id AND MEMBER_ID = p_mem_id
      GROUP BY MEMBER_ID;
      DBMS_OUTPUT.PUT_LINE(v_reserve_times);
      IF v_reserve_times >=1 THEN
         DBMS_OUTPUT.PUT_LINE('Requested item'||' '||p_title_id||' '||'reserved already');
      ELSE 
        INSERT INTO RESERVATION(RES_DATE, MEMBER_ID,TITLE_ID)
        VALUES(SYSDATE,p_mem_id,p_title_id);
        DBMS_OUTPUT.PUT_LINE('Title_ID'||' '||p_title_id||' '||'reserved');
      END IF;
    ELSE 
      DBMS_OUTPUT.PUT_LINE('Title_ID'||' '||p_title_id||' '||v_copy_id||' '||'available');
    END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    raise_application_error(-20114,'Error: Title_id'||' '||p_title_id||' '||
   'or Member_id'||' '||p_mem_id||' '||'not found in Reservations',False);
  WHEN OTHERS THEN
    raise_application_error(-20115,'Error occured with reserving movies',False);

END reserve_movie;


--public
PROCEDURE new_member(
  p_mem_id member.member_id%type,
  p_lname member.last_name%type,
  p_fname member.first_name%type,
  p_addr member.address%type,
  p_city member.city%type,
  p_phone member.phone%type
  )
  IS
    err_code number;
    err_msg  varchar(200);
 BEGIN
      INSERT INTO MEMBER(member_id,last_name,
      first_name,address,city,phone,join_date)
      VALUES
      (p_mem_id,p_lname,p_fname,p_addr,p_city,
       p_phone,TRUNC(SYSDATE));
 EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    err_code := SQLCODE;
    exception_handler(err_code,'new_member');
   WHEN others then
    err_code := SQLCODE;
    exception_handler(err_code,'new_member');
   
END new_member;

--public
FUNCTION new_rental(
p_mem_id rental.member_id%type,
p_title_id rental.title_id%type
)
RETURN DATE IS
  due_date DATE:=Null;
  v_copy_id rental.copy_id%type;
  v_copy_status boolean;
  v_status title_copy.status%type:='AVAILABLE';
  foriegn_key_viloation EXCEPTION;
  PRAGMA EXCEPTION_INIT (foriegn_key_viloation,-2292);
  err_code number;
  v_isMember boolean;
BEGIN
  isMember(p_mem_id,err_code,v_isMember);
  IF v_isMember THEN
    get_copy_status(p_title_id,v_copy_status);
 
    IF v_copy_status=FALSE THEN
      due_date := null;
      reserve_movie(p_mem_id,p_title_id);
    ELSE
      SELECT COPY_ID INTO v_copy_id FROM TITLE_COPY
      WHERE STATUS= v_status 
      AND TITLE_ID = p_title_id
      AND COPY_ID = 
      (SELECT MIN(COPY_ID) FROM TITLE_COPY
      WHERE STATUS= v_status 
      AND TITLE_ID = p_title_id);
    
      UPDATE TITLE_COPY SET STATUS='RENTED'
      WHERE STATUS= v_status 
      AND TITLE_ID = p_title_id
      AND COPY_ID= v_copy_id;

      due_date := SYSDATE + 3;
      INSERT INTO RENTAL(book_date,copy_id,member_id,title_id,act_ret_date,
      exp_ret_date) 
      VALUES(SYSDATE,v_copy_id,p_mem_id,p_title_id,due_date,due_date);
    END IF;
   ELSE
    exception_handler(err_code,'new_rental');
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
  WHEN foriegn_key_viloation THEN
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
  WHEN others then
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
RETURN due_date;
END new_rental;

--public
FUNCTION new_rental(
p_lname MEMBER.LAST_NAME%type,
p_title_id rental.title_id%type 
)
RETURN DATE IS
  due_date DATE:=NULL;
  v_memid member.member_id%type;
  v_copy_id rental.copy_id%type;
  v_copy_status boolean;
  v_status title_copy.status%type:= 'AVAILABLE';
  foriegn_key_viloation EXCEPTION;
  PRAGMA EXCEPTION_INIT (foriegn_key_viloation,-2292);
  err_code number;
  CURSOR c_member IS
    SELECT member_id,last_name,first_name FROM member
    WHERE member.last_name=p_lname;
  v_member c_member%ROWTYPE;
  rCount number:=0;
BEGIN
  
  OPEN c_member;
  Loop
    FETCH c_member INTO v_member;
    rCount := c_member%rowcount;
    EXIT WHEN c_member%NOTFOUND;
    IF rCount > 1 THEN
      DBMS_OUTPUT.PUT_LINE(v_member.member_id||' '||
                         v_member.Last_NAME||', '|| 
                         v_member.first_name);
    ELSE
     v_memid:=v_member.member_id;
    END IF;
  END LOOP;
  CLOSE c_member;
  
IF rCount = 1 THEN
  get_copy_status(p_title_id,v_copy_status);
  IF v_copy_status=FALSE THEN
  due_date := null;
  ELSE
    SELECT COPY_ID INTO v_copy_id FROM TITLE_COPY
    WHERE STATUS= v_status 
    AND TITLE_ID = p_title_id
    AND COPY_ID = 
    (SELECT MIN(COPY_ID) FROM TITLE_COPY
    WHERE STATUS= v_status 
    AND TITLE_ID = p_title_id);
    
    UPDATE TITLE_COPY SET STATUS='RENTED'
    WHERE STATUS= v_status 
    AND TITLE_ID = p_title_id
    AND COPY_ID= v_copy_id;
  
   due_date := SYSDATE + 3;
   INSERT INTO RENTAL(book_date,copy_id,member_id,title_id,act_ret_date,
   exp_ret_date) 
   VALUES(SYSDATE,v_copy_id,v_memid,p_title_id,due_date,due_date);

  END IF;
END IF;

EXCEPTION
  WHEN no_data_found THEN
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
  WHEN foriegn_key_viloation THEN
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
  WHEN others then
    err_code := SQLCODE;
    exception_handler(err_code,'new_rental');
  RETURN due_date;
END new_rental;

--public
PROCEDURE return_movie(
p_title_id title_copy.title_id%type,
p_copy_id TITLE_COPY.COPY_ID%type,
p_status TITLE_COPY.STATUS%type
)
IS
v_title_id title_copy.title_id%type;
v_reservation number:=0;
foriegn_key_viloation EXCEPTION;
PRAGMA EXCEPTION_INIT(foriegn_key_viloation,-2292);
err_code number;

BEGIN

SELECT COUNT(*) INTO v_reservation 
FROM RESERVATION 
WHERE title_id=p_title_id
GROUP BY title_id;

  IF v_reservation > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Title_ID'||' '||p_title_id||' '
    ||'reserved by'||' '||v_reservation||' '||'member/s');
  END IF;
  
  UPDATE RENTAL SET ACT_RET_DATE= SYSDATE
  WHERE TITLE_ID=p_title_id
  AND COPY_ID=p_copy_id;
  
  UPDATE TITLE_COPY SET STATUS=p_status
  WHERE TITLE_ID=p_title_id
  AND COPY_ID=p_copy_id;
  
EXCEPTION
  WHEN no_data_found THEN
    err_code := SQLCODE;
    exception_handler(err_code,'return_movie');
  WHEN foriegn_key_viloation THEN
    err_code := SQLCODE;
    exception_handler(err_code,'return_movie');
  WHEN others then
    err_code := SQLCODE;
    exception_handler(err_code,'return_movie');

END return_movie;

END video_pkg;