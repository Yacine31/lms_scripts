select S.HOST_NAME, S.INSTANCE_NAME, S.COUNT_NBR, S.SDO_OWNER,S.SDO_TABLE_NAME,S.SDO_COLUMN_NAME, BANNER "EDITION"
from test_version V, test_spatial S
where COUNT_NBR > 0
and S.HOST_NAME=V.HOST_NAME and S.INSTANCE_NAME=V.INSTANCE_NAME
and LOCATE('Enterprise', BANNER) > 0
order by HOST_NAME, INSTANCE_NAME;


select distinct physical_server, s.host_name, s.instance_name, banner, concat(o.parameter,' = ', o.value) as 'Spatial Installed'
from test_version v, test_v_option o, test_spatial s left join test_cpu c on s.host_name=c.host_name
where o.host_name=v.host_name and o.instance_name=v.instance_name
and o.parameter='Spatial'
and s.host_name=v.host_name and s.instance_name=v.instance_name
and count_nbr not in ('0','-942')
and locate('Enterprise', banner) > 0
order by physical_server, s.host_name, s.instance_name;

