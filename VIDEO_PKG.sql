create or replace PACKAGE video_pkg
IS
PROCEDURE new_member(
p_mem_id member.member_id%type,
p_lname member.last_name%type,
p_fname member.first_name%type,
p_addr member.address%type,
p_city member.city%type,
p_phone member.phone%type
);

FUNCTION new_rental(
p_mem_id rental.member_id%type,
p_title_id rental.title_id%type
)
return DATE;

FUNCTION new_rental(
p_lname MEMBER.LAST_NAME%type,
p_title_id rental.title_id%type
)
return DATE;
/*
PROCEDURE get_copy_status(
p_title_id IN title.title_id%TYPE,
p_copy_id OUT title_copy.copy_id%TYPE,
check_status OUT BOOLEAN
);


PROCEDURE reserve_movie(
  p_mem_id member.member_id%type,
  p_title_id title.title_id%type
);
*/


PROCEDURE return_movie(
p_title_id title_copy.title_id%type,
p_copy_id TITLE_COPY.COPY_ID%type,
p_status TITLE_COPY.STATUS%type
);



end video_pkg;