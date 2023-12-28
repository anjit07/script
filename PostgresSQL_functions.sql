-- FUNCTION: lgd.findate_new(character)

-- DROP FUNCTION IF EXISTS lgd.findate_new(character);

CREATE OR REPLACE FUNCTION lgd.findate_new(
	finyear character DEFAULT NULL::character(9))
    RETURNS TABLE(start_dt date, end_date date) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

 DECLARE DATE_LOOP text;
 FIN_STRT_DT DATE;
 FIN_STRT TEXT;
FIN_END_DT DATE;
 
BEGIN
   FOR DATE_LOOP IN 
   select A from regexp_split_to_table(FINYEAR,E'\\-') As A LOOP
   if (FIN_STRT_DT is null) then
    FIN_STRT:='01-APR-'||DATE_LOOP;
    FIN_STRT_DT := CAST (FIN_STRT AS DATE);
   else 
    FIN_STRT:='31-mar-'||DATE_LOOP;
    FIN_END_DT := CAST (FIN_STRT AS DATE);    
   end if;
   END LOOP;

   return query select FIN_STRT_DT, FIN_END_DT; 

END;
$BODY$;
--------

-- FUNCTION: lgd.districtwise_financialyearwise_localbody(character varying)

-- DROP FUNCTION IF EXISTS lgd.districtwise_financialyearwise_localbody(character varying);

CREATE OR REPLACE FUNCTION lgd.districtwise_financialyearwise_localbody(
	v_fncl_yr character varying)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

DECLARE STATE_CD INTEGER;

BEGIN

--TRUNCATE TABLE lgd.districtwise_fncl_localbody;
-- select * from lgd.districtwise_financialyearwise_localbody('2019-2020');

FOR STATE_CD IN
	(select s.state_code from lgd.state s where isactive order by s.state_code)
LOOP

RAISE  NOTICE 'State Code-> %', STATE_CD ;
insert into lgd.districtwise_fncl_localbody(select * from lgd.get_finyearwise_and_districtwise_villagelevel_localbody(STATE_CD,v_fncl_yr));
END LOOP;

RETURN 'Inserted' ;

END;

$BODY$;

ALTER FUNCTION lgd.districtwise_financialyearwise_localbody(character varying)
    OWNER TO postgres;
------
-- FUNCTION: lgd.get_assigned_unit_details(character, integer, character)

-- DROP FUNCTION IF EXISTS lgd.get_assigned_unit_details(character, integer, character);

CREATE OR REPLACE FUNCTION lgd.get_assigned_unit_details(
	assigned_unit_category character,
	assigned_unit_code integer,
	finyear character)
    RETURNS TABLE(assigned_unit_cat character, assigned_unit_subcategory integer, assigned_unit_level character, assigned_unit_name_english character varying, assigned_unit_name_local character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE v_start_dt date;
DECLARE v_end_dt date;
DECLARE current_fin_year integer; -- added by Amit on 19-mar-2018
DECLARE enter_fin_year integer;   -- added by Amit on 19-mar-2018
BEGIN
 IF $1 = 'O' THEN
 RETURN QUERY
/*select 
CAST('O' AS character(1)) ,
org_type_code AS assigned_unit_subcategory,
org_level,
org_name,
org_name_local
 from lgd.organization 
 where org_code=$2
   and isactive;*/
   SELECT CAST('O' AS character(1)),
          org.org_type_code,
          CAST(loc_level.located_at_level as character(1)),
          org_unit.org_unit_name,
          org_unit.org_unit_name
     FROM lgd.org_units org_unit 
         ,lgd.org_located_at_levels loc_level
         ,lgd.organization org
    WHERE org_unit.org_unit_code=$2
      AND loc_level.org_located_level_code=org_unit.org_located_level_code
      AND org.olc=loc_level.olc
      AND org_unit.isactive
      AND loc_level.isactive
      AND org.isactive;


ELSIF $1= 'G' THEN  

    -- added by Amit on 19-mar-2018
      select get_finyear_for_adate-1 into current_fin_year from lgd.get_finyear_for_adate ('now()');
      enter_fin_year:=substring(finyear,1,4) :: integer;
      if (  enter_fin_year > current_fin_year ) then 
       FINYEAR :=null;
      end if;
     -- added by Amit on 19-mar-2018
	 
	IF FINYEAR is not null then 
				
		RETURN QUERY
		select CAST('G' AS character(1)),
		a.local_body_type_code,
		local_body_type.level ,
		a.local_body_name_english,
		a.local_body_name_local
		from lgd.localbody a,
		lgd.local_body_type,
		lgd.localbody_finyear b
		where a.local_body_code=b.local_body_code 
		and  a.local_body_version=b.local_body_version 
		and  a.local_body_type_code=local_body_type.local_body_type_code
		and  local_body_type.isactive and b.finyear=$3
		AND  a.local_body_code=$2;
	  
	  
	ELSE
		RETURN QUERY
		select CAST('G' AS character(1)),
		a.local_body_type_code,
		local_body_type.level ,
		local_body_name_english,
		local_body_name_local
		from lgd.localbody a,
		lgd.local_body_type
		where a.local_body_type_code=local_body_type.local_body_type_code
		and  a.isactive
		and  local_body_type.isactive
		AND  a.local_body_code=$2;
	END IF;	
END IF;

END ;
$BODY$;

ALTER FUNCTION lgd.get_assigned_unit_details(character, integer, character)
    OWNER TO postgres;
-------
-- FUNCTION: lgd.get_constituencies_list_by_search_text_fn(character varying, character varying)

-- DROP FUNCTION IF EXISTS lgd.get_constituencies_list_by_search_text_fn(character varying, character varying);

CREATE OR REPLACE FUNCTION lgd.get_constituencies_list_by_search_text_fn(
	character varying,
	character varying)
    RETURNS SETOF lgd.constituency_list 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE rows constituency_list%rowtype;
DECLARE temp_rows char;
DECLARE id int;
BEGIN

SELECT 0 INTO id;

IF strpos($1,'%') != 0 OR strpos($1,'_') != 0 THEN
	RETURN;
END IF;

FOR temp_rows IN
	SELECT DISTINCT * FROM (select CAST(regexp_split_to_table($2, E'\\,') AS CHAR) AS name) AS TBL LOOP
	IF UPPER(temp_rows)='P' THEN
		FOR rows IN
			SELECT 
			  id,
			  'P' AS type,
			  null,
			  null,
			  null,
			  parliament_constituency.pc_code, 
			  parliament_constituency.pc_name_english, 
			  parliament_constituency.pc_name_local, 
			  state.state_code,
			  state.state_name_english, 
			  state.state_name_local
			FROM 
			  parliament_constituency, 
			  state
			WHERE 
			  parliament_constituency.slc = state.slc AND
			  state.isactive = TRUE AND 
			  parliament_constituency.isactive = TRUE AND 
			  UPPER(parliament_constituency.pc_name_english) Like UPPER($1)||'%' LOOP
		SELECT id+1 INTO id;
		SELECT id into rows.id;
		RETURN NEXT rows;
		END LOOP;
	ELSEIF UPPER(temp_rows)='A' THEN
		FOR rows IN
			SELECT 
			  id,
			  'A' AS type,
			  assembly_constituency.ac_code, 
			  assembly_constituency.ac_name_english, 
			  assembly_constituency.ac_name_local, 
			  parliament_constituency.pc_code, 
			  parliament_constituency.pc_name_english, 
			  parliament_constituency.pc_name_local, 
			  state.state_code, 
			  state.state_name_english, 
			  state.state_name_local
			FROM 
			  parliament_constituency, 
			  state, 
			  assembly_constituency
			WHERE 
			  parliament_constituency.slc = state.slc AND
			  assembly_constituency.plc = parliament_constituency.plc AND
			  state.isactive = TRUE AND 
			  parliament_constituency.isactive = TRUE AND 
			  assembly_constituency.isactive = TRUE AND 
			  UPPER(assembly_constituency.ac_name_english) Like UPPER($1)||'%' LOOP
		SELECT id+1 INTO id;
		SELECT id into rows.id;
		RETURN NEXT rows;
		END LOOP;
		
	END IF;
END LOOP;
END;
$BODY$;

ALTER FUNCTION lgd.get_constituencies_list_by_search_text_fn(character varying, character varying)
    OWNER TO postgres;
------
-- FUNCTION: lgd.get_coverage_lb_list_excluding_ward_coverage_fn(character varying)

-- DROP FUNCTION IF EXISTS lgd.get_coverage_lb_list_excluding_ward_coverage_fn(character varying);

CREATE OR REPLACE FUNCTION lgd.get_coverage_lb_list_excluding_ward_coverage_fn(
	character varying)
    RETURNS TABLE(land_region_code integer, land_region_version integer, land_region_name_english character varying, land_region_type character, coverage_type character) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
SELECT 
  land_region_code,
  land_region_version,
  land_region_name_english,
  land_region_type,
  (CASE WHEN tbl.ward_coverage_type='P' THEN 'P' ELSE tbl.coverage_type END) coverage_type
FROM
(
	SELECT 
	  land_coverage.land_region_code,
	  land_coverage.land_region_version,
	  land_coverage.land_region_name_english,
	  land_coverage.land_region_type,
	  land_coverage.coverage_type,
	  ward_coverage.land_region_code as ward_land_region_code,
	  ward_coverage.coverage_type as ward_coverage_type
	FROM get_coverage_lb_list_fn($1) AS land_coverage LEFT JOIN
	get_lb_covered_ward_list_fn($1) AS ward_coverage on
	  land_coverage.land_region_code=ward_coverage.land_region_code AND
	  land_coverage.land_region_version=ward_coverage.land_region_version AND
	  land_coverage.land_region_type=ward_coverage.land_region_type 
)
AS 
  tbl 
WHERE 
  tbl.ward_coverage_type IS NULL OR tbl.ward_coverage_type='P';
$BODY$;

ALTER FUNCTION lgd.get_coverage_lb_list_excluding_ward_coverage_fn(character varying)
    OWNER TO postgres;
---
-- FUNCTION: lgd.get_menu_profile_by_id(text)

-- DROP FUNCTION IF EXISTS lgd.get_menu_profile_by_id(text);

CREATE OR REPLACE FUNCTION lgd.get_menu_profile_by_id(
	menuid text)
    RETURNS TABLE(menu_id integer, resource_id character varying, parent integer, menu_source integer, menu_groupsea integer, item_type character varying, form_name character varying, group_id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

BEGIN

 return query

select a.menu_id,a.resource_id,a.parent,a.menu_source,a.menu_groupsea,a.item_type,a.form_name,a.group_id from lgd.menu_profile a where a.menu_id in (select cast(regexp_split_to_table($1, ',') as int) )  order by a.menu_id,a.menu_groupsea;
END;
$BODY$;

ALTER FUNCTION lgd.get_menu_profile_by_id(text)
    OWNER TO postgres;
---------

-- FUNCTION: lgd.get_org_district_subdistrict(integer, integer)

-- DROP FUNCTION IF EXISTS lgd.get_org_district_subdistrict(integer, integer);

CREATE OR REPLACE FUNCTION lgd.get_org_district_subdistrict(
	integer,
	integer)
    RETURNS TABLE(districtcode integer, districtname character varying, subdistrictcode integer, subdistrictname character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

declare v_olc int;
v_dlc int;
v_tlc int;
v_slc int;
v_org_located_level int;
v_parent_org_unit int;
v_entity_lc int;
loop1 record;
loop2 record;
v_org_unit_code int;

BEGIN
create temp table t1 (districtcode integer, districtname character varying, subdistrictcode integer, subdistrictname character varying);
if $1= 1 then
return query select 0,null:: character varying,0,null:: character varying from lgd.state where isactive and slc=$2;
elsif $1=2 then 
return query select district_code,district_name_english,0,null::character varying from lgd.district where isactive and dlc=$2;
elsif $1=3 then
return query select d.district_code,d.district_name_english,t.subdistrict_code,t.subdistrict_name_english from lgd.district d, lgd.subdistrict t where 
d.dlc=t.dlc and d.isactive and t.isactive and t.tlc=$2;
elsif $1=4 then
return query select d.district_code,d.district_name_english,t.subdistrict_code,t.subdistrict_name_english from lgd.district d, lgd.subdistrict t, lgd.village v 
where v.dlc=d.dlc and v.tlc=t.tlc and d.isactive and t.isactive and v.isactive and v.vlc=$2;
elsif $1=5 then
return query select d.district_code,d.district_name_english,0,null::character varying from lgd.district d,lgd.block b 
where d.dlc=b.dlc and d.isactive and b.isactive and b.blc=$2;

elsif $1>5 then
raise info '1';
for loop1 in select olc  from lgd.org_located_at_levels a, lgd.org_units b, lgd.administration_unit_entity c where a.org_located_level_code=b.org_located_level_code and c.admin_unit_entity_code=b.entity_lc and c.admin_unit_level_code=b.entity_type and a.isactive and b.isactive and c.isactive and c.admin_unit_entity_code=$2 and c.admin_unit_level_code=$1
--select olc  from lgd.org_located_at_levels a, lgd.org_units b, lgd.administration_unit_entity c where a.org_located_level_code=b.org_located_level_code and c.admin_unit_entity_code=b.entity_lc and c.admin_unit_level_code=b.entity_type and a.isactive and b.isactive and c.isactive and c.admin_unit_entity_code=13339 and c.admin_unit_level_code=170
 loop
v_olc := loop1.olc;
raise info 'v_olc =%',v_olc;
--select olc   from lgd.org_located_at_levels a, lgd.org_units b where a.org_located_level_code=b.org_located_level_code and a.isactive and b.isactive and b.entity_lc=207 and b.entity_type=11;


if (select count(*) from lgd.org_located_at_levels o where o.olc=v_olc and o.isactive and located_at_level =2 ) = 0 then
--select count(*) from lgd.org_located_at_levels o where o.olc=701 and o.isactive and located_at_level =2
raise info '2';
select o.slc into v_slc from lgd.org_units ou,lgd.org_located_at_levels ol,lgd.organization o where ou.org_located_level_code=ol.org_located_level_code and ol.olc=o.olc and ou.isactive and ol.isactive and o.isactive and ou.entity_lc=$2 and ou.entity_type=$1 and ol.olc=v_olc;   

raise info 'v_slc =%',v_slc;

if ( with recursive a as ( select admin_unit_entity_code,admin_unit_level_code,parent_unit_entity_code,parent_category ,admin_coverage_code from lgd.administration_unit_entity where isactive and admin_unit_entity_code=$2 and admin_unit_level_code=$1 union select o.admin_unit_entity_code,o.admin_unit_level_code,o.parent_unit_entity_code,o.parent_category,o.admin_coverage_code from lgd.administration_unit_entity o inner join a on o.admin_unit_entity_code=a.parent_unit_entity_code where o.isactive ) select count(a.admin_coverage_code) from a,lgd.administration_unit_level l where a.admin_unit_level_code=l.admin_unit_level_code and l.slc=v_slc and l.isactive and a.admin_coverage_code <> 0 ) <> 0 then 
 
select coalesce(entity_link_code,0) into v_dlc  from lgd.administrative_entity_coverage where admin_coverage_code  in (
with recursive a as ( select admin_unit_entity_code,admin_unit_level_code,parent_unit_entity_code,parent_category ,admin_coverage_code from lgd.administration_unit_entity where isactive and admin_unit_entity_code=$2 and admin_unit_level_code=$1 union select o.admin_unit_entity_code,o.admin_unit_level_code,o.parent_unit_entity_code,o.parent_category,o.admin_coverage_code from lgd.administration_unit_entity o inner join a on o.admin_unit_entity_code=a.parent_unit_entity_code where o.isactive ) select distinct a.admin_coverage_code from a,lgd.administration_unit_level l where a.admin_unit_level_code=l.admin_unit_level_code and l.slc=v_slc and l.isactive ) and isactive and entity_type in ('D' );

else 
v_dlc :=0 ;

end if;
raise info 'v_dlc =%',v_dlc;

 insert into t1 select d.district_code,d.district_name_english,0,null::character varying from lgd.district d where d.district_code= v_dlc and d.isactive;
 

else

raise info 'inside coverage 2';
select a.parent_org_unit_code,a.org_located_level_code into v_parent_org_unit,v_org_located_level from lgd.org_units a,lgd.org_located_at_levels b where a.entity_lc=$2 and a.entity_type =$1 and a.isactive and b.isactive and a.org_located_level_code=b.org_located_level_code and b.olc=v_olc ;
--select a.parent_org_unit_code,a.org_located_level_code from lgd.org_units a,lgd.org_located_at_levels b where a.entity_lc=13339 and a.entity_type =170 and a.isactive and b.isactive and a.org_located_level_code=b.org_located_level_code and b.olc=797 ;

raise info 'v_parent_org_unit =%',v_parent_org_unit;
raise info 'v_org_located_level =%',v_org_located_level;

for loop2 in select o.org_located_level_code from lgd.org_located_at_levels o where o.olc=v_olc and o.isactive and o.located_at_level =2 loop
--select o.* from lgd.org_located_at_levels o where o.olc=797 and o.isactive and o.located_at_level =2 --select o.* from lgd.org_located_at_levels o where o.olc=797
while v_org_located_level <> loop2.org_located_level_code loop
raise info 'in loop';
select org_located_level_code,parent_org_unit_code,entity_lc into v_org_located_level,v_parent_org_unit,v_entity_lc from lgd.org_units where org_unit_code=v_parent_org_unit and isactive;
--select org_located_level_code,parent_org_unit_code,entity_lc  from lgd.org_units where org_unit_code=1225466 and isactive;
raise info 'v_org_located_level in loop =%',v_org_located_level;
raise info 'v_entity_lc in loop =%',v_entity_lc;
end loop;-- end while

raise info 'out from loop';

if (v_org_located_level is null)  then
raise info 'in if ';

select a.parent_org_unit_code,a.org_located_level_code,org_unit_code into v_parent_org_unit,v_org_located_level,v_org_unit_code from lgd.org_units a,lgd.org_located_at_levels b where a.entity_lc=$2 and a.entity_type =$1 and a.isactive and b.isactive and a.org_located_level_code=b.org_located_level_code and b.olc=v_olc ;

raise info 'v_org_unit2 =%',v_org_unit_code;
raise info 'v_parent_org_unit2 =%',v_parent_org_unit;
raise info 'v_org_located_level2 =%',v_org_located_level;


while v_org_located_level <> loop2.org_located_level_code loop
raise info 'in loop2';
select org_located_level_code,parent_org_unit_code,entity_lc,org_unit_code into v_org_located_level,v_parent_org_unit,v_entity_lc,v_org_unit_code from lgd.org_units where parent_org_unit_code=v_org_unit_code and isactive;
--select org_located_level_code,parent_org_unit_code,entity_lc  from lgd.org_units where org_unit_code=1225466 and isactive;
raise info 'v_org_located_level in loop2 =%',v_org_located_level;
raise info 'v_entity_lc in loop2 =%',v_entity_lc;
end loop;-- end while2

end if;

 insert into t1 select d.district_code,d.district_name_english,0,null::character varying from lgd.district d where d.district_code= v_entity_lc and d.isactive;
  end loop; --loop2

end if;

end loop; --loop1
 return query select distinct * from t1;

end if;
drop  table t1;
END;
$BODY$;

----
-- FUNCTION: lgd.get_parent_land_region_wise_entity_details_fn(character, integer, integer, integer)

-- DROP FUNCTION IF EXISTS lgd.get_parent_land_region_wise_entity_details_fn(character, integer, integer, integer);

CREATE OR REPLACE FUNCTION lgd.get_parent_land_region_wise_entity_details_fn(
	character,
	integer DEFAULT NULL::integer,
	integer DEFAULT NULL::integer,
	integer DEFAULT NULL::integer)
    RETURNS SETOF lgd.statewise_entity_details 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE statewise_entity_details_rows lgd.statewise_entity_details%rowtype;
BEGIN
	IF UPPER($1) = 'S' THEN
		FOR statewise_entity_details_rows IN
			SELECT 
			  district.district_code, 
			  district.district_version, 
			  district.district_name_english, 
			  district.district_name_local, 
			  district.alias_english, 
			  district.alias_local, 
			  district.census_2001_code, 
			  district.census_2011_code, 
			  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replaces.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replaces.lrlc AND state.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replaces.lrlc AND district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replaces.lrlc AND subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replaces.lrlc AND block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replaces.lrlc AND village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) END) 
				FROM 
				  lgd.landregion_replaces 
				WHERE 
				  district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) AS replaces,
				  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replacedby.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replacedby.lrlc AND state.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replacedby.lrlc AND district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replacedby.lrlc AND subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replacedby.lrlc AND block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replacedby.lrlc AND village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) END) 
				FROM 
				  lgd.landregion_replacedby
				WHERE 
				  district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) AS replacedby,
			  district.isactive
			FROM 
			  lgd.state, 
			  lgd.district
			WHERE 
			  state.slc = district.slc AND
			  state.isactive = TRUE AND 
			  district.isactive = TRUE AND 
			  state.state_code = COALESCE($2, state.state_code)
			  ORDER BY 3 LIMIT (CASE $3 WHEN null THEN (SELECT count(*) FROM lgd.district WHERE isactive=TRUE) ELSE $3 END) OFFSET (CASE $4 WHEN null THEN 0 ELSE $4 END) LOOP

			RETURN NEXT statewise_entity_details_rows;
		END LOOP;
	ELSEIF $1 = 'D' THEN
		FOR statewise_entity_details_rows IN
			SELECT 
			  subdistrict.subdistrict_code, 
			  subdistrict.subdistrict_version, 
			  subdistrict.subdistrict_name_english, 
			  subdistrict.subdistrict_name_local, 
			  subdistrict.alias_english, 
			  subdistrict.alias_local, 
			  subdistrict.census_2001_code, 
			  subdistrict.census_2011_code, 
			  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replaces.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replaces.lrlc AND state.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replaces.lrlc AND district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replaces.lrlc AND subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replaces.lrlc AND block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replaces.lrlc AND village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) END) 
				FROM 
				  lgd.landregion_replaces 
				WHERE 
				  subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) AS replaces,
				  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replacedby.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replacedby.lrlc AND state.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replacedby.lrlc AND district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replacedby.lrlc AND subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replacedby.lrlc AND block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replacedby.lrlc AND village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) END) 
				FROM 
				  lgd.landregion_replacedby
				WHERE 
				  subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) AS replacedby,
			  subdistrict.isactive
			FROM 
			  lgd.district, 
			  lgd.subdistrict
			WHERE 
			  subdistrict.dlc = district.dlc AND
			  district.isactive = TRUE AND 
			  subdistrict.isactive = TRUE AND 
			  district.district_code = COALESCE($2, district.district_code)
			  ORDER BY 3 LIMIT (CASE $3 WHEN null THEN (SELECT count(*) FROM lgd.subdistrict WHERE isactive=TRUE) ELSE $3 END) OFFSET (CASE $4 WHEN null THEN 0 ELSE $4 END) LOOP

			RETURN NEXT statewise_entity_details_rows;
		END LOOP;
	ELSEIF $1 = 'd' THEN
		FOR statewise_entity_details_rows IN
			SELECT 
			  block.block_code, 
			  block.block_version, 
			  block.block_name_english, 
			  block.block_name_local, 
			  block.alias_english, 
			  block.alias_local, 
			  null, 
			  null, 
			  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replaces.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replaces.lrlc AND state.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replaces.lrlc AND district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replaces.lrlc AND subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replaces.lrlc AND block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replaces.lrlc AND village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) END) 
				FROM 
				  lgd.landregion_replaces 
				WHERE 
				  block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) AS replaces,
				  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replacedby.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replacedby.lrlc AND state.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replacedby.lrlc AND district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replacedby.lrlc AND subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replacedby.lrlc AND block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replacedby.lrlc AND village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) END) 
				FROM 
				  lgd.landregion_replacedby
				WHERE 
				  block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) AS replacedby,
			  block.isactive
			FROM 
			  lgd.district, 
			  lgd.block
			WHERE 
			  block.dlc = district.dlc AND
			  district.isactive = TRUE AND 
			  block.isactive = TRUE AND 
			  district.district_code = COALESCE($2, district.district_code)
			  ORDER BY 3 LIMIT (CASE $3 WHEN null THEN (SELECT count(*) FROM lgd.block WHERE isactive=TRUE) ELSE $3 END) OFFSET (CASE $4 WHEN null THEN 0 ELSE $4 END) LOOP

			RETURN NEXT statewise_entity_details_rows;
		END LOOP;
	ELSEIF UPPER($1) = 'B' THEN
		FOR statewise_entity_details_rows IN
			SELECT 
			  village.village_code, 
			  village.village_version, 
			  village.village_name_english, 
			  village.village_name_local, 
			  village.alias_english, 
			  village.alias_local, 
			  village.census_2001_code, 
			  village.census_2011_code, 
			  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replaces.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replaces.lrlc AND state.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replaces.lrlc AND district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replaces.lrlc AND subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replaces.lrlc AND block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replaces.lrlc AND village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) END) 
				FROM 
				  lgd.landregion_replaces 
				WHERE 
				  village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) AS replaces,
				  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replacedby.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replacedby.lrlc AND state.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replacedby.lrlc AND district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replacedby.lrlc AND subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replacedby.lrlc AND block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replacedby.lrlc AND village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) END) 
				FROM 
				  lgd.landregion_replacedby
				WHERE 
				  village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) AS replacedby,
			  village.isactive
			FROM 
			  lgd.subdistrict, 
			  lgd.village
			WHERE 
			  subdistrict.tlc = village.tlc AND
			  subdistrict.isactive = TRUE AND 
			  village.isactive = TRUE AND 
			  subdistrict.subdistrict_code = COALESCE($2, subdistrict.subdistrict_code)
			  ORDER BY 3 LIMIT (CASE $3 WHEN null THEN (SELECT count(*) FROM lgd.village WHERE isactive=TRUE) ELSE $3 END) OFFSET (CASE $4 WHEN null THEN 0 ELSE $4 END) LOOP

			RETURN NEXT statewise_entity_details_rows;
		END LOOP;		
	ELSEIF UPPER($1) = 'T' THEN
		FOR statewise_entity_details_rows IN
			SELECT 
			  village.village_code, 
			  village.village_version, 
			  village.village_name_english, 
			  village.village_name_local, 
			  village.alias_english, 
			  village.alias_local, 
			  village.census_2001_code, 
			  village.census_2011_code, 
			  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replaces.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replaces.lrlc AND state.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replaces.lrlc AND district.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replaces.lrlc AND subdistrict.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replaces.lrlc AND block.lr_replaces = landregion_replaces.lr_replaces), ' , ')) 
								      WHEN landregion_replaces.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replaces.lrlc AND village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) END) 
				FROM 
				  lgd.landregion_replaces 
				WHERE 
				  village.lr_replaces = landregion_replaces.lr_replaces), ' , ')) AS replaces,
				  (SELECT array_to_string(array( SELECT (CASE WHEN landregion_replacedby.entity_type = 'S' THEN (SELECT array_to_string(array(select state_name_english||' (STATE)' from lgd.state WHERE slc = landregion_replacedby.lrlc AND state.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'D' THEN (SELECT array_to_string(array(select district_name_english||' (DISTRICT)' from lgd.district WHERE dlc = landregion_replacedby.lrlc AND district.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'T' THEN (SELECT array_to_string(array(select subdistrict_name_english||' (SUBDISTRICT)' from lgd.subdistrict WHERE tlc = landregion_replacedby.lrlc AND subdistrict.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'B' THEN (SELECT array_to_string(array(select block_name_english||' (BLOCK)' from lgd.block WHERE blc = landregion_replacedby.lrlc AND block.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) 
									      WHEN landregion_replacedby.entity_type = 'V' THEN (SELECT array_to_string(array(select village_name_english||' (VILLAGE)' from lgd.village WHERE vlc = landregion_replacedby.lrlc AND village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) END) 
				FROM 
				  lgd.landregion_replacedby
				WHERE 
				  village.lr_replacedby = landregion_replacedby.lr_replacedby), ' , ')) AS replacedby,
			  village.isactive
			FROM 
			  lgd.subdistrict, 
			  lgd.village
			WHERE 
			  subdistrict.tlc = village.tlc AND
			  subdistrict.isactive = TRUE AND 
			  village.isactive = TRUE AND 
			  subdistrict.subdistrict_code = COALESCE($2, subdistrict.subdistrict_code)
			  ORDER BY 3 LIMIT (CASE $3 WHEN null THEN (SELECT count(*) FROM lgd.village WHERE isactive=TRUE) ELSE $3 END) OFFSET (CASE $4 WHEN null THEN 0 ELSE $4 END) LOOP

			RETURN NEXT statewise_entity_details_rows;
		END LOOP;
	END IF;

END;
$BODY$;



CREATE OR REPLACE FUNCTION generate_ilike_condition(input_text VARCHAR)
RETURNS VARCHAR AS
$$
DECLARE
    condition_text VARCHAR := '';
    word_array VARCHAR[];
BEGIN
    -- Step 1: Split the input text into an array of words
    SELECT ARRAY(SELECT regexp_split_to_table(input_text, '\s+')) INTO word_array;

    -- Step 2: Construct the ILIKE condition
    FOR i IN 1..array_length(word_array, 1) LOOP
        condition_text := condition_text || 'cd_code ILIKE ' || quote_literal('%' || word_array[i] || '%');
        IF i < array_length(word_array, 1) THEN
            condition_text := condition_text || ' OR ';
        END IF;
    END LOOP;

    RETURN condition_text;
END;
$$
LANGUAGE plpgsql;



select * from search_state('bi');

CREATE OR REPLACE FUNCTION search_state(input_text VARCHAR)
RETURNS setof lgd.state 
LANGUAGE plpgsql
as $BODY$
DECLARE
    condition_text VARCHAR := '';
   -- word_array VARCHAR[];
BEGIN
    
    CREATE TABLE temp_table AS lgd.state;
        
    FOR condition_text IN
         SELECT ARRAY(SELECT regexp_split_to_table(input_text, '\s+'))
    LOOP

    RAISE  NOTICE 'condition_text-> %', condition_text ;
    insert into temp_table select * from lgd.state where state_name_english ilike '%'||condition_text||'%';
    END LOOP;

    RETURN query select * from temp_table;
END;
$BODY$


