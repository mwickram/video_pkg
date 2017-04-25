EXEC DBMS_OUTPUT.PUT_LINE(video_pkg.new_rental(110, 98))
EXEC DBMS_OUTPUT.PUT_LINE(video_pkg.new_rental(109, 93))
EXEC DBMS_OUTPUT.PUT_LINE(video_pkg.new_rental(107, 98))
EXEC DBMS_OUTPUT.PUT_LINE(video_pkg.new_rental('Biri', 97))
EXEC DBMS_OUTPUT.PUT_LINE(video_pkg.new_rental(97, 97))

set serveroutput on;
set verify off;

DECLARE

--p_copy_id title_copy.copy_id%TYPE;
--check_status BOOLEAN;
dueDate DATE;

BEGIN
--video_pkg.get_copy_status(92,p_copy_id,check_status);
--dueDate:=video_pkg.new_rental(110,92);

DBMS_OUTPUT.PUT_LINE('   ');
      DBMS_OUTPUT.PUT_LINE('Member_ID'||' '||
                           'Last_Name'||' '|| 
                           'First_Name');
dueDate:=video_pkg.new_rental('Biri',92);
DBMS_OUTPUT.PUT_LINE(' ');
if dueDate is null then
 DBMS_OUTPUT.PUT_LINE('no copies available');
else
  DBMS_OUTPUT.PUT_LINE('reuturn date:' || ' '||dueDate);
end if;
--IF check_status=true  then

--DBMS_OUTPUT.PUT_LINE('yes'||' '||p_copy_id);
--else 
--DBMS_OUTPUT.PUT_LINE('no'||' '||p_copy_id);


--end if;

END;

--SELECT Last_name, Member_id FROM MEMBER WHERE LAST_NAME='Nagayama';

Execute VIDEO_PKG.RETURN_MOVIE(92,1,'AVAILABLE');


DUP_VAL_ON_INDEX