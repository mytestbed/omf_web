#!/bin/bash
sed -i 's/00:00:00:00:c1:00/client1/g' nodes_groundtruth.csv
sed -i 's/00:00:00:00:c2:00/client2/g' nodes_groundtruth.csv
sed -i 's/10:10:10:10:10:fe/Internet/g' nodes_groundtruth.csv
sed -i 's/ba:5e:ba:11:00:00/WWWServer/g' nodes_groundtruth.csv
sed -i 's/ba:5e:ba:11:00:01/WWWServer/g' nodes_groundtruth.csv
sed -i 's/ba:5e:ba:11:ad:00/admin/g' nodes_groundtruth.csv
sed -i 's/ba:5e:ba:11:db:00/PsqlServer/g' nodes_groundtruth.csv

sed -i 's/00:00:00:00:c1:00/client1/g' links_groundtruth.csv
sed -i 's/00:00:00:00:c2:00/client2/g' links_groundtruth.csv
sed -i 's/10:10:10:10:10:fe/Internet/g' links_groundtruth.csv
sed -i 's/ba:5e:ba:11:00:00/WWWServer/g' links_groundtruth.csv
sed -i 's/ba:5e:ba:11:00:01/WWWServer/g' links_groundtruth.csv
sed -i 's/ba:5e:ba:11:ad:00/admin/g' links_groundtruth.csv
sed -i 's/ba:5e:ba:11:db:00/PsqlServer/g' links_groundtruth.csv
