# cleaning script
# adds month_id
# and this month_id is used to create the date_id
# this way we can match with dim_date

sed -E '
1s/^month,/month,month_id,/
2,${
  s/^(januari),/\1,01,/
  s/^(februari),/\1,02,/
  s/^(maart),/\1,03,/
  s/^(april),/\1,04,/
  s/^(mei),/\1,05,/
  s/^(juni),/\1,06,/
  s/^(juli),/\1,07,/
  s/^(augustus),/\1,08,/
  s/^(september),/\1,09,/
  s/^(oktober),/\1,10,/
  s/^(november),/\1,11,/
  s/^(december),/\1,12,/
}
' cgvs-figures.csv | awk -F',' 'BEGIN {OFS=","}
NR==1 {
  print $0,"date_id"
}
NR>1 {
  print $0,$3 $2 "01"
}' > clean-cgvs-figures.csv
