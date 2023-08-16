# v2t-utils
convert [NsxObjectCapture](https://github.com/vmware-archive/powernsx/blob/master/tools/DiagramNSX/NsxObjectCapture.ps1) result (xml files) to csv

# Usage
PS > convert_nsxv_xml_to_csv.ps1 -env_list_file xxx.csv -output_base /path/to/output

## env_list_file
csv file that contains environment name and NsxObjectCapture result path(directory) like this

```
env,path
prod,"/path/to/Nsx-ObjectCapture-prod"
dev,"/path/to/Nsx-ObjectCapture-dev"
```

## results
output csv files will be in the output_base dir as follows

```
$ cd /path/to/output
$ ls prod dev
dev:
dfw.csv		edge.csv	lb.csv		ospf.csv	srv.csv
dhcp.csv	gwfw.csv	ls.csv		pg.csv		vm.csv
dlr.csv		ipset.csv	nat.csv		sg.csv

prod:
dfw.csv		edge.csv	lb.csv		ospf.csv	srv.csv
dhcp.csv	gwfw.csv	ls.csv		pg.csv		vm.csv
dlr.csv		ipset.csv	nat.csv		sg.csv
$
```

## csv files to Excel
output csv files can be collected in an Excel bool with [create_excel_from_csv.ps1](https://github.com/mu853/pwsh-utils/tree/main#create_excel_from_csvps1)
