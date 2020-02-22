bin/neo4j-admin import \
	--nodes "/import/dataset/nodes-1.csv,/import/dataset/nodes-2.csv" \
	--relationships "/import/dataset/relations.csv" \
	--delimiter="," \
	--array-delimiter="|" \
	--ignore-missing-nodes=true
